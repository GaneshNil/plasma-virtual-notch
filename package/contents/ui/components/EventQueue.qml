import QtQuick

/*
 * EventQueue.qml
 * Central arbiter for Dynamic Island temporary activity pulses and state transitions.
 * Prioritizes high-urgency events (e.g. microphone stream, notifications) over ambient states.
 */
QtObject {
    id: queue

    // Event priorities
    readonly property int priorityAmbient: 0
    readonly property int priorityNormal: 1
    readonly property int priorityMedium: 2
    readonly property int priorityUrgent: 3

    // Active event details
    property string activeModuleId: ""
    property string activeReason: ""
    property int currentPriority: 0
    property bool hasActiveEvent: false
    property color activeAccentColor: "#c77dff"

    // Default duration in milliseconds
    property int defaultDurationMs: 3500

    // Internal queue array of { moduleId, reason, priority, durationMs, accentColor }
    property var _pendingEvents: []

    // Timer to automatically expire active event and revert to compact state
    property Timer _expireTimer: Timer {
        interval: queue.defaultDurationMs
        repeat: false
        onTriggered: queue.popNextEvent()
    }

    function postEvent(moduleId, reason, priority, durationMs, accentColor) {
        if (durationMs === undefined || durationMs <= 0) durationMs = defaultDurationMs;
        if (priority === undefined) priority = priorityNormal;

        // If current event has lower priority, preempt it immediately
        if (!hasActiveEvent || priority > currentPriority) {
            _activateEvent(moduleId, reason, priority, durationMs, accentColor);
        } else {
            // Append to queue sorted by priority
            var list = _pendingEvents.slice();
            list.push({
                moduleId: moduleId,
                reason: reason,
                priority: priority,
                durationMs: durationMs,
                accentColor: accentColor
            });
            list.sort(function(a, b) { return b.priority - a.priority; });
            _pendingEvents = list;
        }
    }

    function _activateEvent(moduleId, reason, priority, durationMs, accentColor) {
        activeModuleId = moduleId;
        activeReason = reason;
        currentPriority = priority;
        activeAccentColor = accentColor || "#c77dff";
        hasActiveEvent = true;

        _expireTimer.stop();
        _expireTimer.interval = durationMs;
        _expireTimer.start();
    }

    function popNextEvent() {
        if (_pendingEvents.length > 0) {
            var next = _pendingEvents.shift();
            _activateEvent(next.moduleId, next.reason, next.priority, next.durationMs, next.accentColor);
        } else {
            hasActiveEvent = false;
            activeModuleId = "";
            activeReason = "";
            currentPriority = 0;
            _expireTimer.stop();
        }
    }

    function clearModuleEvents(moduleId) {
        if (activeModuleId === moduleId) {
            popNextEvent();
        }
        var filtered = _pendingEvents.filter(function(e) { return e.moduleId !== moduleId; });
        _pendingEvents = filtered;
    }
}
