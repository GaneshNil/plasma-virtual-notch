import QtQuick

/*
 * BaseModule.qml
 * Abstract interface contract for all Dynamic Island feature modules.
 * Ensures zero resource usage when disabled and standardized communication with
 * the Island state controller.
 */
Item {
    id: moduleRoot

    // The host context (root PlasmoidItem in main.qml)
    property var host: null

    // Module identifier
    property string moduleId: ""

    // Whether this module is activated in settings
    property bool moduleEnabled: true

    // Event priority: 0 = Ambient/Low, 1 = Normal/Info, 2 = Medium/Transient, 3 = High/Urgent
    property int priority: 0

    // Whether this module currently requests an Activity State (temporary expansion)
    property bool requestsActivity: false

    // Descriptive tag for active state (e.g., "mic_in_use", "track_change", "new_notification")
    property string activityReason: ""

    // Accent color suggestion when this module dominates the Island
    property color preferredAccentColor: host ? host.cAccent : "#c77dff"

    // Emitted when a transient event happens that should briefly wake up the island
    signal triggerActivity(string reason, int durationMs)
}

