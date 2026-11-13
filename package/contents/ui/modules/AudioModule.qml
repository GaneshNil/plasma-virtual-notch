import QtQuick
import org.kde.plasma.private.volume as Vol

/*
 * AudioModule.qml
 * Master volume control, mute/unmute, and volume change alerts.
 */
BaseModule {
    id: audioMod
    moduleId: "volume"
    priority: 2
    preferredAccentColor: host ? host.cAccent : "#c77dff"

    Vol.SinkModel { id: sinkModel }
    readonly property var preferredSink: sinkModel.preferredSink
    readonly property int volume: preferredSink ? Math.round(preferredSink.volume / 655.36) : 0
    readonly property bool muted: preferredSink ? preferredSink.muted : false

    function toggleMute() {
        if (preferredSink) preferredSink.muted = !preferredSink.muted;
    }

    function setVolume(pct) {
        if (!preferredSink) return;
        var clamped = Math.max(0, Math.min(100, pct));
        preferredSink.volume = Math.round(clamped * 655.36);
    }

    // Trigger Dynamic Island pulse on volume changes
    onVolumeChanged: {
        if (moduleEnabled && host && host.eventQueue && !host.open) {
            host.eventQueue.postEvent("volume", "Volume: " + volume + "%" + (muted ? " (Muted)" : ""), 2, 2200, preferredAccentColor);
        }
    }
}
