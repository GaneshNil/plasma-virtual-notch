import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM

/*
 * NetworkModule.qml
 * Full NetworkManager integration: status, SSID, signal strength, Wi-Fi toggle.
 */
BaseModule {
    id: netMod
    moduleId: "network"
    priority: 1
    preferredAccentColor: host ? host.cCyan : "#5cf2ff"

    PlasmaNM.ConnectionIcon {
        id: connIcon
    }

    PlasmaNM.WirelessStatus {
        id: wirelessStatus
    }

    PlasmaNM.EnabledConnections {
        id: enabledConnections
    }

    readonly property string iconName: connIcon.connectionIcon || "network-wireless-symbolic"
    readonly property bool isConnecting: connIcon.connecting
    readonly property string ssid: wirelessStatus.wifiSSID || ""
    readonly property bool isConnected: ssid !== "" || (connIcon.connectionIcon !== "" && !connIcon.connectionIcon.includes("disconnected") && !connIcon.connectionIcon.includes("unavailable"))
    readonly property bool wifiEnabled: enabledConnections.wirelessEnabled

    function toggleWifi() {
        enabledConnections.wirelessEnabled = !enabledConnections.wirelessEnabled;
    }
}
