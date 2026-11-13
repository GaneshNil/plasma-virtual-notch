import QtQuick

/*
 * BrightnessModule.qml
 * Display backlight control communicating directly via Solid PowerManagement D-Bus.
 */
BaseModule {
    id: brightMod
    moduleId: "brightness"
    priority: 1
    preferredAccentColor: host ? host.cWarn : "#ffd75c"

    property int brightness: 40

    function setBrightness(pct) {
        var clamped = Math.max(1, Math.min(100, pct));
        brightness = clamped;
        if (host && host.backendBridge) {
            host.backendBridge.setBrightness(clamped);
        }
    }
}
