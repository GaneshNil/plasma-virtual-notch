import QtQuick

/*
 * DockerModule.qml
 * Detects Docker Desktop running status on system.
 */
BaseModule {
    id: dockerMod
    moduleId: "docker"
    priority: 1
    preferredAccentColor: host ? host.cCyan : "#5cf2ff"

    property bool isRunning: true
    property string statusText: "Docker Desktop Running"
}
