import QtQuick

/*
 * BackendBridge.qml
 * Full two-way execution bridge running control_bridge.py for system controls:
 * - Wallpaper Gallery (Scan ~/Pictures/Wallpapers, set wallpaper + MaterialYou via Matugen)
 * - Brightness (Solid PowerManagement D-Bus)
 * - Power Profile (net.hadess.PowerProfiles)
 * - Klipper History (Copy / Clear)
 * - Wi-Fi & Bluetooth
 */
QtObject {
    id: bridge

    readonly property string apiBase: "http://127.0.0.1:19842"

    property string powerProfile: "balanced"
    property int brightnessPct: 40
    property var clipboardHistory: []
    property bool wifiEnabled: true
    property bool btPowered: true

    // Wallpaper state
    property var wallpapers: []
    property string currentWallpaper: ""
    property string wallpaperSearch: ""
    property bool isLoadingWallpapers: false

    readonly property var filteredWallpapers: {
        if (!wallpapers || wallpapers.length === 0) return [];
        if (!wallpaperSearch || wallpaperSearch.trim() === "") return wallpapers;
        var query = wallpaperSearch.trim().toLowerCase();
        return wallpapers.filter(function(item) {
            return (item.name && item.name.toLowerCase().indexOf(query) !== -1) ||
                   (item.filename && item.filename.toLowerCase().indexOf(query) !== -1);
        });
    }

    // Auto-refresh timer to keep hardware and system settings in 2-way sync
    property var syncTimer: Timer {
        interval: 3500; repeat: true; running: true; triggeredOnStart: true
        onTriggered: {
            bridge.loadState();
            if (bridge.wallpapers.length === 0) {
                bridge.loadWallpapers();
            }
        }
    }

    function httpGet(endpoint, callback) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", apiBase + endpoint, true);
        xhr.timeout = 2500;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var res = JSON.parse(xhr.responseText);
                        if (callback) callback(null, res);
                    } catch (e) {
                        if (callback) callback(e, null);
                    }
                } else {
                    if (callback) callback("HTTP " + xhr.status, null);
                }
            }
        };
        xhr.onerror = function() {
            if (callback) callback("Network error", null);
        };
        xhr.send();
    }

    function httpPost(endpoint, data, callback) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", apiBase + endpoint, true);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.timeout = 4000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var res = JSON.parse(xhr.responseText);
                        if (callback) callback(null, res);
                    } catch (e) {
                        if (callback) callback(e, null);
                    }
                } else {
                    if (callback) callback("HTTP " + xhr.status, null);
                }
            }
        };
        xhr.onerror = function() {
            if (callback) callback("Network error", null);
        };
        xhr.send(JSON.stringify(data || {}));
    }

    function loadState() {
        httpGet("/api/state", function(err, res) {
            if (!err && res) {
                if (res.power_profile) bridge.powerProfile = res.power_profile;
                if (res.brightness_pct !== undefined) bridge.brightnessPct = res.brightness_pct;
                if (res.clipboard_history) bridge.clipboardHistory = res.clipboard_history;
                if (res.wifi_enabled !== undefined) bridge.wifiEnabled = res.wifi_enabled;
                if (res.bt_powered !== undefined) bridge.btPowered = res.bt_powered;
                if (res.current_wallpaper) bridge.currentWallpaper = res.current_wallpaper;
            }
        });
    }

    function loadWallpapers() {
        isLoadingWallpapers = true;
        httpGet("/api/wallpapers", function(err, res) {
            isLoadingWallpapers = false;
            if (!err && res) {
                if (res.wallpapers) bridge.wallpapers = res.wallpapers;
                if (res.current_wallpaper) bridge.currentWallpaper = res.current_wallpaper;
            }
        });
    }

    function setWallpaper(path) {
        if (!path) return;
        currentWallpaper = path;
        httpPost("/api/set_wallpaper", { path: path }, function(err, res) {
            if (!err) {
                bridge.loadState();
            }
        });
    }

    function setBrightness(pct) {
        brightnessPct = pct;
        httpPost("/api/set_brightness", { pct: pct }, function(err, res) {
            if (!err && res && res.brightness_pct !== undefined) {
                brightnessPct = res.brightness_pct;
            }
        });
    }

    function setPowerProfile(profile) {
        powerProfile = profile;
        httpPost("/api/set_power_profile", { profile: profile }, function(err, res) {
            if (!err && res && res.power_profile) {
                powerProfile = res.power_profile;
            }
        });
    }

    function copyClipboard(text) {
        httpPost("/api/copy_clipboard", { text: text }, function(err, res) {
            if (!err) bridge.loadState();
        });
    }

    function clearClipboard() {
        clipboardHistory = [];
        httpPost("/api/clear_clipboard", {}, function(err, res) {
            if (!err) bridge.clipboardHistory = [];
        });
    }
}
