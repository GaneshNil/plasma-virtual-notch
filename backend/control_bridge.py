#!/usr/bin/env python3
"""
Dynamic Island Full Two-Way Control Bridge
Connects QML directly to:
- net.hadess.PowerProfiles (get/set profile: power-saver, balanced, performance)
- Solid BrightnessControl (get/set brightness via D-Bus)
- Klipper (get history, set clipboard item, clear all history)
- NetworkManager (WiFi on/off, get APs)
- BlueZ (Bluetooth on/off)
"""
import sys, json, dbus

def handle_request(req):
    action = req.get("action")
    data = req.get("data", {})
    sbus = dbus.SessionBus()
    sysbus = dbus.SystemBus()

    if action == "get_state":
        res = {}
        # 1. Power Profile
        try:
            pp = sysbus.get_object("net.hadess.PowerProfiles", "/net/hadess/PowerProfiles")
            props = dbus.Interface(pp, "org.freedesktop.DBus.Properties")
            res["power_profile"] = str(props.Get("net.hadess.PowerProfiles", "ActiveProfile"))
        except Exception as e:
            res["power_profile"] = "balanced"

        # 2. Brightness
        try:
            solid = sbus.get_object("org.kde.Solid.PowerManagement", "/org/kde/Solid/PowerManagement/Actions/BrightnessControl")
            b_iface = dbus.Interface(solid, "org.kde.Solid.PowerManagement.Actions.BrightnessControl")
            cur = int(b_iface.brightness())
            mx = int(b_iface.brightnessMax())
            res["brightness_pct"] = int((cur / mx) * 100) if mx > 0 else 40
        except Exception as e:
            res["brightness_pct"] = 40

        # 3. Klipper History
        try:
            klipper = sbus.get_object("org.kde.klipper", "/klipper")
            k_iface = dbus.Interface(klipper, "org.kde.klipper.klipper")
            hist = [str(item) for item in k_iface.getClipboardHistoryMenu()[:15]]
            res["clipboard_history"] = hist
        except Exception as e:
            res["clipboard_history"] = []

        # 4. WiFi
        try:
            nm = sysbus.get_object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
            props = dbus.Interface(nm, "org.freedesktop.DBus.Properties")
            res["wifi_enabled"] = bool(props.Get("org.freedesktop.NetworkManager", "WirelessEnabled"))
        except Exception as e:
            res["wifi_enabled"] = True

        # 5. Bluetooth
        try:
            bluez = sysbus.get_object("org.bluez", "/org/bluez/hci0")
            props = dbus.Interface(bluez, "org.freedesktop.DBus.Properties")
            res["bt_powered"] = bool(props.Get("org.bluez.Adapter1", "Powered"))
        except Exception as e:
            res["bt_powered"] = True

        return res

    elif action == "set_power_profile":
        profile = str(data.get("profile", "balanced"))
        try:
            pp = sysbus.get_object("net.hadess.PowerProfiles", "/net/hadess/PowerProfiles")
            props = dbus.Interface(pp, "org.freedesktop.DBus.Properties")
            props.Set("net.hadess.PowerProfiles", "ActiveProfile", profile)
            return {"ok": True, "power_profile": profile}
        except Exception as e:
            return {"error": str(e)}

    elif action == "set_brightness":
        pct = max(1, min(100, int(data.get("pct", 40))))
        try:
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
            klipper = sbus.get_object("org.kde.klipper", "/klipper")
            k_iface = dbus.Interface(klipper, "org.kde.klipper.klipper")
            k_iface.setClipboardContents(text)
            return {"ok": True, "copied": text[:30]}
        except Exception as e:
            return {"error": str(e)}

    elif action == "clear_clipboard":
        try:
            klipper = sbus.get_object("org.kde.klipper", "/klipper")
            k_iface = dbus.Interface(klipper, "org.kde.klipper.klipper")
            k_iface.clearClipboardHistory()
            return {"ok": True}
        except Exception as e:
            return {"error": str(e)}

    elif action == "set_wifi_enabled":
        val = bool(data.get("enabled", True))
        try:
            nm = sysbus.get_object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
            props = dbus.Interface(nm, "org.freedesktop.DBus.Properties")
            props.Set("org.freedesktop.NetworkManager", "WirelessEnabled", val)
            return {"ok": True, "wifi_enabled": val}
        except Exception as e:
            return {"error": str(e)}

    elif action == "set_bt_powered":
        val = bool(data.get("powered", True))
        try:
            bluez = sysbus.get_object("org.bluez", "/org/bluez/hci0")
            props = dbus.Interface(bluez, "org.freedesktop.DBus.Properties")
            props.Set("org.bluez.Adapter1", "Powered", val)
            return {"ok": True, "bt_powered": val}
        except Exception as e:
            return {"error": str(e)}

    return {"error": "unknown action"}

if __name__ == "__main__":
    if len(sys.argv) > 1:
        req = json.loads(sys.argv[1])
        print(json.dumps(handle_request(req)))
    else:
        print(json.dumps(handle_request({"action": "get_state"})))
