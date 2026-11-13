import QtQuick
import org.kde.bluezqt as BluezQt

/*
 * BluetoothModule.qml
 * Bluetooth adapter state and connected devices.
 */
BaseModule {
    id: btMod
    moduleId: "bluetooth"
    priority: 1
    preferredAccentColor: host ? host.cCyan : "#5cf2ff"

    readonly property bool isBluetoothEnabled: BluezQt.Manager.bluetoothOperational
    readonly property bool isConnected: BluezQt.Manager.connectedDevices.length > 0
    readonly property int deviceCount: BluezQt.Manager.connectedDevices.length
}
