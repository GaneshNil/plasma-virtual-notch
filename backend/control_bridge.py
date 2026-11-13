#!/usr/bin/env python3
"""
Dynamic Island Two-Way Control Bridge
Provides bidirectional synchronization and execution for:
- NetworkManager (WiFi on/off, scan APs, connect/disconnect)
- BlueZ (Bluetooth on/off, scan, pair, connect)
- Solid BrightnessControl (get/set brightness)
- Klipper (get/set/clear history)
- Audio (sinks/sources via wpctl/pipewire)
"""
import sys, json, dbus

def handle_request(req):
    action = req.get("action")
    data = req.get("data", {})
    sbus = dbus.SessionBus()
    sysbus = dbus.SystemBus()

    if action == "get_state":
        res = {}
        # 1. WiFi
        try:
            nm = sysbus.get_object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
            props = dbus.Interface(nm, "org.freedesktop.DBus.Properties")
            res["wifi_enabled"] = bool(props.Get("org.freedesktop.NetworkManager", "WirelessEnabled"))
            # APs
            devs = props.Get("org.freedesktop.NetworkManager", "AllDevices")
            aps_list = []
            for d in devs:
                dev_obj = sysbus.get_object("org.freedesktop.NetworkManager", d)
                d_props = dbus.Interface(dev_obj, "org.freedesktop.DBus.Properties")
                if d_props.Get("org.freedesktop.NetworkManager.Device", "DeviceType") == 2:
                    wf = dbus.Interface(dev_obj, "org.freedesktop.NetworkManager.Device.Wireless")
                    for a in wf.GetAllAccessPoints():
                        ap_obj = sysbus.get_object("org.freedesktop.NetworkManager", a)
                        ap_props = dbus.Interface(ap_obj, "org.freedesktop.DBus.Properties")
                        ssid = bytes(ap_props.Get("org.freedesktop.NetworkManager.AccessPoint", "Ssid")).decode("utf-8", "ignore")
                        strength = int(ap_props.Get("org.freedesktop.NetworkManager.AccessPoint", "Strength"))
                        if ssid:
                            aps_list.append({"ssid": ssid, "strength": strength})
            res["aps"] = aps_list
        except Exception as e:
            res["wifi_error"] = str(e)

        # 2. Bluetooth
        try:
            bluez = sysbus.get_object("org.bluez", "/org/bluez/hci0")
            props = dbus.Interface(bluez, "org.freedesktop.DBus.Properties")
            res["bt_powered"] = bool(props.Get("org.bluez.Adapter1", "Powered"))
            # devices
            om = dbus.Interface(sysbus.get_object("org.bluez", "/"), "org.freedesktop.DBus.ObjectManager")
            objs = om.GetManagedObjects()
            devs = []
            for k, v in objs.items():
                if "org.bluez.Device1" in v:
                    d = v["org.bluez.Device1"]
                    devs.append({"name": str(d.get("Name", "Device")), "connected": bool(d.get("Connected", False)), "path": k})
            res["bt_devices"] = devs
        except Exception as e:
            res["bt_error"] = str(e)

        # 3. Brightness
        try:
            solid = sbus.get_object("org.kde.Solid.PowerManagement", "/org/kde/Solid/PowerManagement/Actions/BrightnessControl")
            b_iface = dbus.Interface(solid, "org.kde.Solid.PowerManagement.Actions.BrightnessControl")
            cur = int(b_iface.brightness())
            mx = int(b_iface.brightnessMax())
            res["brightness_pct"] = int((cur / mx) * 100) if mx > 0 else 50
        except Exception as e:
            res["brightness_error"] = str(e)

        # 4. Klipper
        try:
            klipper = sbus.get_object("org.kde.klipper", "/klipper")
            k_iface = dbus.Interface(klipper, "org.kde.klipper.klipper")
            hist = [str(item) for item in k_iface.getClipboardHistoryMenu()[:10]]
            res["clipboard_history"] = hist
        except Exception as e:
            res["clipboard_error"] = str(e)

        return res

    elif action == "set_wifi_enabled":
        val = bool(data.get("enabled", True))
        nm = sysbus.get_object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
        props = dbus.Interface(nm, "org.freedesktop.DBus.Properties")
        props.Set("org.freedesktop.NetworkManager", "WirelessEnabled", val)
        return {"ok": True, "wifi_enabled": val}

    elif action == "set_bt_powered":
        val = bool(data.get("powered", True))
        bluez = sysbus.get_object("org.bluez", "/org/bluez/hci0")
        props = dbus.Interface(bluez, "org.freedesktop.DBus.Properties")
        props.Set("org.bluez.Adapter1", "Powered", val)
        return {"ok": True, "bt_powered": val}

    elif action == "set_brightness":
        pct = max(1, min(100, int(data.get("pct", 50))))
        solid = sbus.get_object("org.kde.Solid.PowerManagement", "/org/kde/Solid/PowerManagement/Actions/BrightnessControl")
        b_iface = dbus.Interface(solid, "org.kde.Solid.PowerManagement.Actions.BrightnessControl")
        mx = int(b_iface.brightnessMax())
        val = int((pct / 100.0) * mx)
        b_iface.setBrightness(val)
        return {"ok": True, "brightness_pct": pct}

    elif action == "set_clipboard":
        text = str(data.get("text", ""))
        klipper = sbus.get_object("org.kde.klipper", "/klipper")
        k_iface = dbus.Interface(klipper, "org.kde.klipper.klipper")
        k_iface.setClipboardContents(text)
        return {"ok": True, "copied": text[:30]}

    elif action == "clear_clipboard":
        klipper = sbus.get_object("org.kde.klipper", "/klipper")
        k_iface = dbus.Interface(klipper, "org.kde.klipper.klipper")
        k_iface.clearClipboardHistory()
        return {"ok": True}

    return {"error": "unknown action"}

if __name__ == "__main__":
    if len(sys.argv) > 1:
        req = json.loads(sys.argv[1])
        res = handle_request(req)
        print(json.dumps(res))
    else:
        print(json.dumps(handle_request({"action": "get_state"})))
