import QtQuick
import org.kde.plasma.private.volume as Vol

/*
 * MicrophoneModule.qml
 * Detects microphone streams using PipeWire / PulseAudio SourceOutputModel.
 */
BaseModule {
    id: micMod
    moduleId: "microphone"
    priority: 3
    preferredAccentColor: host ? host.cMic : "#ff9f43"

    property var activeApps: []
    readonly property bool isMicInUse: moduleEnabled && activeApps.length > 0

    readonly property var ignoreRe: /easyeffects|pulseeffects|cava|pavucontrol|plasma|kmix|speech-dispatcher|xdg-desktop-portal/i

    Instantiator {
        id: sourceInst
        active: micMod.moduleEnabled
        model: Vol.SourceModel {}
        delegate: QtObject { readonly property var obj: model.PulseObject }
        onObjectAdded: Qt.callLater(micMod.recompute)
        onObjectRemoved: Qt.callLater(micMod.recompute)
    }

    Instantiator {
        id: outInst
        active: micMod.moduleEnabled
        model: Vol.SourceOutputModel {}
        delegate: QtObject {
            readonly property var obj: model.PulseObject
            readonly property bool corked: obj ? obj.corked : true
            readonly property int dev: obj ? obj.deviceIndex : -1
            onCorkedChanged: Qt.callLater(micMod.recompute)
            onDevChanged: Qt.callLater(micMod.recompute)
        }
        onObjectAdded: Qt.callLater(micMod.recompute)
        onObjectRemoved: Qt.callLater(micMod.recompute)
    }

    function appName(o) {
        const p = o.properties || {};
        return (o.client && o.client.name) || p["application.name"] || p["node.name"] || o.name || "App";
    }

    function recompute() {
        if (!moduleEnabled) { activeApps = []; return; }
        const monitors = {};
        for (let i = 0; i < sourceInst.count; i++) {
            const s = sourceInst.objectAt(i);
            if (s && s.obj && String(s.obj.name).endsWith(".monitor")) monitors[s.obj.index] = true;
        }
        const apps = [];
        for (let i = 0; i < outInst.count; i++) {
            const d = outInst.objectAt(i);
            if (!d || !d.obj) continue;
            const o = d.obj;
            if (o.virtualStream || o.corked || monitors[o.deviceIndex]) continue;
            const p = o.properties || {};
            const n = appName(o);
            if (ignoreRe.test(n) || ignoreRe.test(p["application.process.binary"] || "")) continue;
            if (apps.indexOf(n) < 0) apps.push(n);
        }

        if (apps.join("|") !== activeApps.join("|")) {
            if (apps.length > 0 && activeApps.length === 0 && host && host.eventQueue) {
                host.eventQueue.postEvent("microphone", "Mic active: " + apps.join(", "), 3, 4000, preferredAccentColor);
            }
            activeApps = apps;
        }
    }
}
