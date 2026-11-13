import QtQuick
import org.kde.networkmanager as NetworkManager

/*
 * NetworkModule.qml
 * Wi-Fi SSID, connection state, and network transitions.
 */
BaseModule {
    id: netMod
    moduleId: "network"
    priority: 1
    preferredAccentColor: host ? host.cCyan : "#5cf2ff"

    readonly property bool connected: NetworkManager.NetworkStatus.state === NetworkManager.NetworkStatus.Connected
    readonly property bool connecting: NetworkManager.NetworkStatus.state === NetworkManager.NetworkStatus.Connecting
    readonly property string connectionState: NetworkManager.NetworkStatus.state
}
