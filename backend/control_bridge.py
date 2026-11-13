#!/usr/bin/env python3
"""
Dynamic Island Full Two-Way Control Bridge
Connects QML directly to:
- net.hadess.PowerProfiles (get/set profile: power-saver, balanced, performance)
- Solid BrightnessControl (get/set brightness via D-Bus)
- Klipper (get history, set clipboard item, clear all history)
- NetworkManager (WiFi on/off, get APs)
- BlueZ (Bluetooth on/off)
- Wallpapers (list /home/ganesh/Pictures/Wallpapers, get current, set via set-dynamic-wallpaper.sh)
- Plasmoid toggle (open/close island directly to Wallpapers tab)
"""
import sys, os, glob, json, subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn

WALLPAPER_DIR = os.path.expanduser("~/Pictures/Wallpapers")
SET_WALLPAPER_SCRIPT = os.path.expanduser("~/bin/set-dynamic-wallpaper.sh")
PLASMA_CONFIG = os.path.expanduser("~/.config/plasma-org.kde.plasma.desktop-appletsrc")

def get_session_bus():
    import dbus
    return dbus.SessionBus()

def get_system_bus():
    import dbus
    return dbus.SystemBus()

def get_wallpapers():
    files = []
    for ext in ("*.jpg", "*.jpeg", "*.png", "*.webp"):
        files.extend(glob.glob(os.path.join(WALLPAPER_DIR, ext)))
    
    def sort_key(f):
        base = os.path.splitext(os.path.basename(f))[0]
        return (0, int(base)) if base.isdigit() else (1, base.lower())
    
    files.sort(key=sort_key)
    return [{
        "name": os.path.splitext(os.path.basename(f))[0],
        "filename": os.path.basename(f),
        "path": f,
        "url": "file://" + f
    } for f in files]

def get_current_wallpaper():
    try:
        if os.path.exists(PLASMA_CONFIG):
            with open(PLASMA_CONFIG, "r", encoding="utf-8", errors="ignore") as fp:
                for line in fp:
                    if line.startswith("Image=file://"):
                        return line.strip().split("Image=file://")[1]
    except Exception:
        pass
    return ""

def set_wallpaper_image(image_path):
    if not os.path.isfile(image_path):
        return {"error": f"File not found: {image_path}"}
    try:
        cmd = ["/usr/bin/bash", SET_WALLPAPER_SCRIPT, image_path]
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return {"ok": True, "path": image_path}
    except Exception as e:
        return {"error": str(e)}

def toggle_island_tab(tab_index=3):
    try:
        sbus = get_session_bus()
        import dbus
        ps = sbus.get_object("org.kde.plasmashell", "/PlasmaShell")
        iface = dbus.Interface(ps, "org.kde.PlasmaShell")
        script = f"""
        var c = panels().concat(desktops());
        for (var i = 0; i < c.length; i++) {{
            var w = c[i].widgets('io.github.wnibraj.virtualnotch');
            for (var j = 0; j < w.length; j++) {{
                var open = w[j].readConfig('open', 'false');
                var activeTab = w[j].readConfig('activeTab', '0');
                w[j].currentConfigGroup = ['General'];
                if (open === 'true' && activeTab === '{tab_index}') {{
                    w[j].writeConfig('hover', 0);
                    w[j].writeConfig('open', false);
                }} else {{
                    w[j].writeConfig('activeTab', {tab_index});
                    w[j].writeConfig('hover', 3);
                    w[j].writeConfig('open', true);
                }}
                w[j].reloadConfig();
            }}
        }}
        """
        iface.evaluateScript(script)
        return {"ok": True, "tab": tab_index}
    except Exception as e:
        return {"error": str(e)}

def handle_request(req):
    action = req.get("action")
    data = req.get("data", {})
    
    if action == "get_state":
        res = {}
        try:
            sbus = get_session_bus()
            sysbus = get_system_bus()
            import dbus
            
            # Power Profile
            try:
                pp = sysbus.get_object("net.hadess.PowerProfiles", "/net/hadess/PowerProfiles")
                props = dbus.Interface(pp, "org.freedesktop.DBus.Properties")
                res["power_profile"] = str(props.Get("net.hadess.PowerProfiles", "ActiveProfile"))
            except Exception:
                res["power_profile"] = "balanced"

            # Brightness
            try:
                solid = sbus.get_object("org.kde.Solid.PowerManagement", "/org/kde/Solid/PowerManagement/Actions/BrightnessControl")
                b_iface = dbus.Interface(solid, "org.kde.Solid.PowerManagement.Actions.BrightnessControl")
                cur = int(b_iface.brightness())
                mx = int(b_iface.brightnessMax())
                res["brightness_pct"] = int((cur / mx) * 100) if mx > 0 else 40
            except Exception:
                res["brightness_pct"] = 40

            # Klipper History
            try:
                klipper = sbus.get_object("org.kde.klipper", "/klipper")
                k_iface = dbus.Interface(klipper, "org.kde.klipper.klipper")
                hist = [str(item) for item in k_iface.getClipboardHistoryMenu()[:15]]
                res["clipboard_history"] = hist
            except Exception:
                res["clipboard_history"] = []

            # WiFi
            try:
                nm = sysbus.get_object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
                props = dbus.Interface(nm, "org.freedesktop.DBus.Properties")
                res["wifi_enabled"] = bool(props.Get("org.freedesktop.NetworkManager", "WirelessEnabled"))
            except Exception:
                res["wifi_enabled"] = True

            # Bluetooth
            try:
                bluez = sysbus.get_object("org.bluez", "/org/bluez/hci0")
                props = dbus.Interface(bluez, "org.freedesktop.DBus.Properties")
                res["bt_powered"] = bool(props.Get("org.bluez.Adapter1", "Powered"))
            except Exception:
                res["bt_powered"] = True
        except Exception as e:
            res["error"] = str(e)
            
        res["current_wallpaper"] = get_current_wallpaper()
        return res

    elif action == "get_wallpapers":
        return {
            "wallpapers": get_wallpapers(),
            "current_wallpaper": get_current_wallpaper()
        }

    elif action == "set_wallpaper":
        path = str(data.get("path", ""))
        return set_wallpaper_image(path)

    elif action == "toggle_island":
        tab = int(data.get("tab", 3))
        return toggle_island_tab(tab)

    elif action == "set_power_profile":
        profile = str(data.get("profile", "balanced"))
        try:
            import dbus
            sysbus = get_system_bus()
            pp = sysbus.get_object("net.hadess.PowerProfiles", "/net/hadess/PowerProfiles")
            props = dbus.Interface(pp, "org.freedesktop.DBus.Properties")
            props.Set("net.hadess.PowerProfiles", "ActiveProfile", profile)
            return {"ok": True, "power_profile": profile}
        except Exception as e:
            return {"error": str(e)}

    elif action == "set_brightness":
        pct = max(1, min(100, int(data.get("pct", 40))))
        try:
            import dbus
            sbus = get_session_bus()
            solid = sbus.get_object("org.kde.Solid.PowerManagement", "/org/kde/Solid/PowerManagement/Actions/BrightnessControl")
            b_iface = dbus.Interface(solid, "org.kde.Solid.PowerManagement.Actions.BrightnessControl")
            mx = int(b_iface.brightnessMax())
            val = int((pct / 100.0) * mx)
            b_iface.setBrightness(val)
            return {"ok": True, "brightness_pct": pct}
        except Exception as e:
            return {"error": str(e)}

    elif action == "copy_clipboard":
        text = str(data.get("text", ""))
        try:
            import dbus
            sbus = get_session_bus()
            klipper = sbus.get_object("org.kde.klipper", "/klipper")
            k_iface = dbus.Interface(klipper, "org.kde.klipper.klipper")
            k_iface.setClipboardContents(text)
            return {"ok": True, "copied": text[:30]}
        except Exception as e:
            return {"error": str(e)}

    elif action == "clear_clipboard":
        try:
            import dbus
            sbus = get_session_bus()
            klipper = sbus.get_object("org.kde.klipper", "/klipper")
            k_iface = dbus.Interface(klipper, "org.kde.klipper.klipper")
            k_iface.clearClipboardHistory()
            return {"ok": True}
        except Exception as e:
            return {"error": str(e)}

    return {"error": f"unknown action {action}"}

class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True

class BridgeHTTPHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        if self.path == "/api/wallpapers":
            res = handle_request({"action": "get_wallpapers"})
        elif self.path == "/api/state":
            res = handle_request({"action": "get_state"})
        elif self.path == "/api/toggle_wallpaper":
            res = handle_request({"action": "toggle_island", "data": {"tab": 3}})
        else:
            res = {"status": "running", "service": "Dynamic Island Control Bridge"}
        
        body = json.dumps(res).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self._send_cors_headers()
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b"{}"
        try:
            req_data = json.loads(body.decode("utf-8"))
        except Exception:
            req_data = {}

        if self.path == "/api/set_wallpaper":
            res = handle_request({"action": "set_wallpaper", "data": req_data})
        elif self.path == "/api/set_brightness":
            res = handle_request({"action": "set_brightness", "data": req_data})
        elif self.path == "/api/set_power_profile":
            res = handle_request({"action": "set_power_profile", "data": req_data})
        elif self.path == "/api/copy_clipboard":
            res = handle_request({"action": "copy_clipboard", "data": req_data})
        elif self.path == "/api/clear_clipboard":
            res = handle_request({"action": "clear_clipboard"})
        elif self.path == "/api/toggle_island":
            res = handle_request({"action": "toggle_island", "data": req_data})
        else:
            res = handle_request(req_data)

        resp_bytes = json.dumps(res).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(resp_bytes)))
        self._send_cors_headers()
        self.end_headers()
        self.wfile.write(resp_bytes)

    def log_message(self, format, *args):
        pass

def run_server(port=19842):
    server = ThreadedHTTPServer(("127.0.0.1", port), BridgeHTTPHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()

if __name__ == "__main__":
    if "--daemon" in sys.argv:
        run_server()
    elif len(sys.argv) > 1:
        try:
            req = json.loads(sys.argv[1])
            print(json.dumps(handle_request(req)))
        except Exception as e:
            print(json.dumps({"error": str(e)}))
    else:
        print(json.dumps(handle_request({"action": "get_state"})))
