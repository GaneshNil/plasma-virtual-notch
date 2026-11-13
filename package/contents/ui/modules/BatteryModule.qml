import QtQuick
import org.kde.plasma.private.battery as BatteryModel

/*
 * BatteryModule.qml
 * Battery percentage, charging status and AC power detection.
 */
BaseModule {
    id: batMod
    moduleId: "battery"
    priority: 2
    preferredAccentColor: host ? host.cGood : "#5cffa0"

    readonly property bool hasBattery: host ? host.hasBattery : false
    readonly property real percent: host ? host.v_batPct : 0
    readonly property bool isCharging: host ? (host.v_batRate > 0.5) : false

    onIsChargingChanged: {
        if (moduleEnabled && host && host.eventQueue && hasBattery) {
            var msg = isCharging ? "Charging: " + Math.round(percent) + "%" : "On Battery: " + Math.round(percent) + "%";
            host.eventQueue.postEvent("battery", msg, 2, 3000, isCharging ? preferredAccentColor : (percent < 20 ? host.cHot : host.cWarn));
        }
    }
}

