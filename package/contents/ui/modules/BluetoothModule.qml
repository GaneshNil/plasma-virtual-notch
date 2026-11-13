import QtQuick
import org.kde.bluezqt as BluezQt

/*
 * BluetoothModule.qml
 * Bluetooth adapter state, operational readiness, and paired/connected devices.
 */
BaseModule {
    id: btMod
    moduleId: "bluetooth"
    priority: 1
    preferredAccentColor: host ? host.cCyan : "#5cf2ff"

    readonly property bool isOperational: BluezQt.Manager ? BluezQt.Manager.bluetoothOperational : false
    readonly property bool isBluetoothBlocked: BluezQt.Manager ? BluezQt.Manager.bluetoothBlocked : false
    readonly property var connectedDevices: BluezQt.Manager ? BluezQt.Manager.connectedDevices : []
    readonly property bool hasConnectedDevices: connectedDevices.length > 0
    readonly property int deviceCount: connectedDevices.length

    readonly property string statusText: {
        if (!isOperational) return "Bluetooth Off";
        if (hasConnectedDevices) {
            var first = connectedDevices[0];
            var devName = (first && first.name) ? first.name : "Device";
            return deviceCount > 1 ? devName + " (+" + (deviceCount - 1) + ")" : devName;
        }
        return "Bluetooth On";
    }
}
