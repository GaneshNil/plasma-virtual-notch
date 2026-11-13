#!/usr/bin/env bash
# Virtual Notch installer for KDE Plasma 6 (Wayland).
# Installs for the current user only (no sudo). Safe to re-run: updates in place.
set -euo pipefail

ID="io.github.wnibraj.virtualnotch"
KWIN_ID="virtualnotch"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Options:  --city "Name"   show weather for this city on the notch ("" = turn weather off)
CITY=""; CITY_SET=0
while [ $# -gt 0 ]; do
    case "$1" in
        --city)   [ $# -ge 2 ] || { echo "--city needs a value" >&2; exit 1; }; CITY="$2"; CITY_SET=1; shift 2 ;;
        --city=*) CITY="${1#--city=}"; CITY_SET=1; shift ;;
        -h|--help) echo "Usage: ./install.sh [--city \"Your City\"]"; exit 0 ;;
        *) echo "Unknown option: $1 (try --help)" >&2; exit 1 ;;
    esac
done
CITY="$(printf '%s' "$CITY" | tr -d "'\\\"\n")"

say()  { printf '\033[1;35m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m xx\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- checks
for c in kpackagetool6 kwriteconfig6 busctl; do
    command -v "$c" >/dev/null || die "'$c' not found. Virtual Notch needs KDE Plasma 6 (and systemd's busctl)."
done
busctl --user status org.kde.plasmashell >/dev/null 2>&1 \
    || die "Plasma isn't running. Run this from inside your Plasma session (not over SSH/TTY)."
[ "${XDG_SESSION_TYPE:-}" = "wayland" ] \
    || warn "This doesn't look like a Wayland session. The notch overlay only works on Plasma Wayland."

# ---------------------------------------------------------------- install packages
say "Installing / upgrading the widget package"
kpackagetool6 -t Plasma/Applet -u "$HERE/package" >/dev/null 2>&1 \
    || kpackagetool6 -t Plasma/Applet -i "$HERE/package" >/dev/null \
    || die "Could not install the widget package."

say "Installing / upgrading the KWin hover helper"
kpackagetool6 -t KWin/Script -u "$HERE/kwin-script" >/dev/null 2>&1 \
    || kpackagetool6 -t KWin/Script -i "$HERE/kwin-script" >/dev/null \
    || die "Could not install the KWin script."

kwriteconfig6 --file kwinrc --group Plugins --key "${KWIN_ID}Enabled" true
busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting unloadScript s "$KWIN_ID" >/dev/null 2>&1 || true
busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure >/dev/null 2>&1 || true
sleep 1
if ! busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting isScriptLoaded s "$KWIN_ID" 2>/dev/null | grep -q true; then
    SCRIPT="$(kpackagetool6 -t KWin/Script -s "$KWIN_ID" 2>/dev/null | tail -n1)"
    [ -d "$SCRIPT" ] || SCRIPT="${XDG_DATA_HOME:-$HOME/.local/share}/kwin/scripts/$KWIN_ID"
    busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting loadScript ss "$SCRIPT/contents/code/main.js" "$KWIN_ID" >/dev/null 2>&1 || true
    busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting start >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------- detect sensors
say "Detecting hardware sensors"
SENSORS="$(busctl --user call org.kde.ksystemstats1 /org/kde/ksystemstats1 org.kde.ksystemstats1 allSensors 2>/dev/null \
           | grep -oE '"[^" ]+"' | tr -d '"' | sort -V || true)"
pick() { printf '%s\n' "$SENSORS" | grep -E "$1" | head -n1 || true; }
GPU="$(pick '^gpu/gpu[0-9]+/temperature$' | sed 's|/temperature$||')"
[ -n "$GPU" ] || GPU="$(pick '^gpu/gpu[0-9]+/usage$' | sed 's|/usage$||')"
BAT="$(pick '^power/[^/]+/chargePercentage$' | sed 's|/chargePercentage$||')"
FAN="$(pick '^lmsensors/[^/]+/fan[0-9]+$')"
SSD="$(pick '^lmsensors/nvme[^/]*/temp[0-9]+$')"
printf '    GPU:     %s\n    Battery: %s\n    Fan:     %s\n    SSD:     %s\n' \
    "${GPU:-none}" "${BAT:-none}" "${FAN:-none}" "${SSD:-none}"

# ---------------------------------------------------------------- configure plasmoid
say "Configuring widget instance"
JS="var id='$ID', ws=[], ps=panels(), ds=desktops();
if (locked) { print('LOCKED'); } else {
  var cs = ps.concat(ds);
  for (var i = 0; i < cs.length; i++) ws = ws.concat(cs[i].widgets(id));
  if (!ws.length) { var host = ps.length ? ps[0] : ds[0]; ws = [host.addWidget(id)]; }
  for (var j = 0; j < ws.length; j++) {
    var w = ws[j]; w.currentConfigGroup = ['General'];
    if ('$GPU' !== '') w.writeConfig('gpuSensor', '$GPU');
    if ('$BAT' !== '') w.writeConfig('batterySensor', '$BAT');
    if ('$FAN' !== '') w.writeConfig('fanSensor', '$FAN');
    if ('$SSD' !== '') w.writeConfig('ssdSensor', '$SSD');
    if ($CITY_SET) w.writeConfig('weatherCity', '$CITY');
    w.reloadConfig();
  }
  print('OK ' + ws.length);
}"
OUT="$(busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$JS" 2>&1 || true)"
case "$OUT" in
    *LOCKED*) die "Your widgets are locked. Unlock them (right-click desktop → Unlock Widgets) and re-run." ;;
    *OK*)     ;;
    *)        die "Couldn't add the widget: $OUT" ;;
esac

say "Virtual Notch Dynamic Island is active!"
echo "    • Right-click the widget in your panel to open graphical settings (Geometry, Colors, Modules)"
echo "    • Push cursor to top edge above the notch → expands to dashboard card"
echo "    • Media track changes, mic usage and notifications pulse the island automatically"
echo "    • Uninstall any time with ./uninstall.sh"
