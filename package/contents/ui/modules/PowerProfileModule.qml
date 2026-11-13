import QtQuick

/*
 * PowerProfileModule.qml
 * Switches between Power Saver, Balanced and Performance modes via net.hadess.PowerProfiles D-Bus.
 */
BaseModule {
    id: powerMod
    moduleId: "power"
    priority: 1
    preferredAccentColor: host ? host.cAccent : "#c77dff"

    property string currentProfile: "balanced"

    function cycleProfile() {
        if (currentProfile === "power-saver") setProfile("balanced");
        else if (currentProfile === "balanced") setProfile("performance");
        else setProfile("power-saver");
    }

    function setProfile(p) {
        currentProfile = p;
        if (host && host.backendBridge) {
            host.backendBridge.setPowerProfile(p);
        }
    }
}

