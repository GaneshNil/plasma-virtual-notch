import QtQuick
import org.kde.plasma.private.volume as Vol

/*
 * AudioModule.qml
 * Full PipeWire master volume & microphone controller with sink/source access.
 */
BaseModule {
    id: audioMod
    moduleId: "volume"
    priority: 2
    preferredAccentColor: host ? host.cAccent : "#c77dff"

    Vol.SinkModel { id: sinkModel }
    Vol.SourceModel { id: sourceModel }

    readonly property var preferredSink: sinkModel.preferredSink
    readonly property var preferredSource: sourceModel.defaultSource

    readonly property int volume: preferredSink ? Math.round(preferredSink.volume / 655.36) : 0
    readonly property bool muted: preferredSink ? preferredSink.muted : false
    readonly property string sinkName: preferredSink ? (preferredSink.description || preferredSink.name || "Output") : "Default Audio"

    readonly property int micVolume: preferredSource ? Math.round(preferredSource.volume / 655.36) : 0
    readonly property bool micMuted: preferredSource ? preferredSource.muted : false
    readonly property string sourceName: preferredSource ? (preferredSource.description || preferredSource.name || "Input") : "Default Mic"

    function toggleMute() {
        if (preferredSink) preferredSink.muted = !preferredSink.muted;
    }

    function toggleMicMute() {
        if (preferredSource) preferredSource.muted = !preferredSource.muted;
    }

    function setVolume(pct) {
        if (!preferredSink) return;
        var clamped = Math.max(0, Math.min(100, pct));
        preferredSink.volume = Math.round(clamped * 655.36);
    }

    function setMicVolume(pct) {
        if (!preferredSource) return;
        var clamped = Math.max(0, Math.min(100, pct));
        preferredSource.volume = Math.round(clamped * 655.36);
    }

    // Trigger Dynamic Island pulse on volume changes
    onVolumeChanged: {
        if (moduleEnabled && host && host.eventQueue && !host.open) {
            host.eventQueue.postEvent("volume", "Volume: " + volume + "%" + (muted ? " (Muted)" : ""), 2, 2200, preferredAccentColor);
        }
    }
}
