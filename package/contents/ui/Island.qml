import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import org.kde.kirigami as Kirigami

// The visible Dynamic Island: Compact Notch + Activity Pill + Expanded Dashboard Card.
Item {
    id: island
    property var n // Host PlasmoidItem in main.qml

    // State definitions
    // 0 = Compact, 1 = Expanded (open card), 2 = Activity (dynamic event pulse)
    readonly property bool isExpanded: n.open
    readonly property bool isActivity: !isExpanded && n.eventQueue && n.eventQueue.hasActiveEvent
    readonly property bool isCompact: !isExpanded && !isActivity

    // Slide up out of sight when mouse is near in compact mode (so browser tabs remain clickable)
    readonly property bool shouldHide: n.slideAwayEnabled && n.hidden && !isExpanded
    y: shouldHide ? -(height + 24) : 0
    opacity: shouldHide ? 0 : 1
    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 180 } }

    // Dynamic width & height morphing based on active state
    property int targetWidth: {
        if (isExpanded) return n.cardW;
        if (isActivity) return Math.min(n.cardW - 40, n.notchW + 80);
        return n.notchW + (n.micActive ? 30 : 0);
    }
    property int targetHeight: {
        if (isExpanded) return cardContent.implicitHeight;
        if (isActivity) return n.notchH + 8;
        return n.notchH;
    }

    width: targetWidth
    height: targetHeight
    Behavior on width  { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 0.85 } }
    Behavior on height { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 0.85 } }

    // Corner radius morphing
    property real currentRadius: isExpanded ? n.cardCornerRadius : (isActivity ? 18 : n.notchCornerRadius)
    Behavior on currentRadius { NumberAnimation { duration: 280 } }

    // Dynamic Rim Color and Lighting
    readonly property color activeAccent: {
        if (isActivity && n.eventQueue && n.eventQueue.activeAccentColor) {
            return n.eventQueue.activeAccentColor;
        }
        if (n.micActive) return n.cMic;
        if (n.playing) return n.cPink;
        return n.cAccent;
    }
    readonly property color rimColor: Qt.lighter(activeAccent, 1.2)
    readonly property real rimAlpha: {
        if (!n.rimGlowEnabled) return 0.0;
        if (n.micActive) return (0.45 + 0.55 * pulse.v);
        if (isActivity) return 0.95;
        if (n.playing) return 0.90;
        return 0.75;
    }

    // Unified continuous shape: top fillets (shoulders) + rounded body + drop shadow
    Shape {
        id: outline
        readonly property real f: n.fillet
        readonly property real w: island.width
        readonly property real h: island.height
        readonly property real rr: Math.min(island.currentRadius, island.height - n.fillet)

        x: -f; y: 0
        width: w + 2 * f; height: h + 2
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: n.rimGlowEnabled
        layer.samples: 4
        layer.effect: MultiEffect {
            autoPaddingEnabled: true
            shadowEnabled: n.rimGlowEnabled
            shadowColor: island.rimColor
            shadowBlur: 0.5
            shadowOpacity: 0.35 * island.rimAlpha
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }
        ShapePath {
            fillColor: Qt.rgba(n.cBg.r, n.cBg.g, n.cBg.b, n.customBackgroundOpacity)
            strokeColor: Qt.rgba(island.rimColor.r, island.rimColor.g, island.rimColor.b, island.rimAlpha)
            strokeWidth: 1
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 0; startY: 0
            PathArc  { x: outline.f; y: outline.f; radiusX: outline.f; radiusY: outline.f; direction: PathArc.Clockwise }
            PathLine { x: outline.f; y: outline.h - outline.rr }
            PathArc  { x: outline.f + outline.rr; y: outline.h; radiusX: outline.rr; radiusY: outline.rr; direction: PathArc.Counterclockwise }
            PathLine { x: outline.f + outline.w - outline.rr; y: outline.h }
            PathArc  { x: outline.f + outline.w; y: outline.h - outline.rr; radiusX: outline.rr; radiusY: outline.rr; direction: PathArc.Counterclockwise }
            PathLine { x: outline.f + outline.w; y: outline.f }
            PathArc  { x: outline.w + 2 * outline.f; y: 0; radiusX: outline.f; radiusY: outline.f; direction: PathArc.Clockwise }
        }
    }

    // Body content clipping container
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        topLeftRadius: 0; topRightRadius: 0
        bottomLeftRadius: island.currentRadius
        bottomRightRadius: island.currentRadius
        clip: true

        // ----------------- 1. COMPACT STATE -----------------
        Item {
            id: compactState
            anchors.fill: parent
            opacity: island.isCompact ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            // Simulated camera lens aperture
            Rectangle {
                anchors.centerIn: parent
                width: 10; height: 10; radius: 5
                color: "#06060b"; border.color: "#161624"; border.width: 1
                Rectangle { x: 2.5; y: 2.5; width: 3; height: 3; radius: 1.5; color: "#2b3c70" }
            }

            // Left side: Clock / Microphone indicator
            Item {
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                width: parent.width / 2 - 26; height: parent.height
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatTime(clock.now, "hh:mm")
                    color: n.cText; font.family: n.monoFont; font.pixelSize: 12; font.weight: Font.Medium
                    opacity: n.micActive ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    opacity: n.micActive ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 7; height: 7; radius: 3.5; color: n.cMic; opacity: pulse.v }
                    Kirigami.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16
                        source: "audio-input-microphone-symbolic"; color: n.cMic; isMask: true
                    }
                }
            }

            // Right side: Active equalizer / Weather / CPU Temp fallback
            Item {
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                width: parent.width / 2 - 26; height: parent.height

                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: parent.width; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight
                    text: n.micApps.length > 1 ? n.micApps.length + " apps" : (n.micApps[0] || "")
                    color: n.cMic; font.family: n.monoFont; font.pixelSize: 11
                    opacity: n.micActive ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                Equalizer {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    n: island.n; active: n.playing && !n.micActive && island.isCompact
                    opacity: n.playing && !n.micActive ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 5
                    opacity: !n.playing && !n.micActive && n.weatherOk && n.enableWeather ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Kirigami.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16
                        source: n.weatherIcon || ""
                    }
                    Text {
                        text: n.weatherOk ? Math.round(n.weatherTemp) + "°" : ""
                        color: n.cText; font.family: n.monoFont; font.pixelSize: 12; font.weight: Font.Medium
                    }
                }
                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 5
                    opacity: !n.playing && !n.micActive && (!n.weatherOk || !n.enableWeather) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 6; height: 6; radius: 3; color: n.tempColor(n.v_cpuTemp) }
                    Text {
                        text: n.v_cpuTemp > 0 ? Math.round(n.v_cpuTemp) + "°" : "--°"
                        color: n.cText; font.family: n.monoFont; font.pixelSize: 12; font.weight: Font.Medium
                    }
                }
            }
        }

        // ----------------- 2. ACTIVITY STATE (Dynamic Island Pulse) -----------------
        Item {
            id: activityState
            anchors.fill: parent
            opacity: island.isActivity ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            Row {
                anchors.centerIn: parent
                spacing: 10

                Kirigami.Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18; height: 18
                    source: {
                        if (!n.eventQueue) return "dialog-information";
                        var mod = n.eventQueue.activeModuleId;
                        if (mod === "media") return "media-playback-start-symbolic";
                        if (mod === "notifications") return "mail-unread-symbolic";
                        if (mod === "volume") return "audio-volume-high-symbolic";
                        if (mod === "usb") return "drive-removable-media-symbolic";
                        if (mod === "battery") return "battery-charging-symbolic";
                        if (mod === "network") return "network-wireless-symbolic";
                        if (mod === "bluetooth") return "bluetooth-active-symbolic";
                        return "dialog-information";
                    }
                    color: island.activeAccent
                    isMask: true
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: n.eventQueue ? n.eventQueue.activeReason : ""
                    color: n.cText
                    font.family: n.monoFont
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        // ----------------- 3. EXPANDED STATE (Dashboard Card) -----------------
        StatsCard {
            id: cardContent
            n: island.n
            width: n.cardW
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            opacity: island.isExpanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 260 } }
        }
    }

    // Shared Clock Timer
    Timer {
        id: clock
        property date now: new Date()
        interval: island.isExpanded ? 1000 : 10000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: now = new Date()
    }

    // Shared pulse animation for mic badge & glow
    QtObject {
        id: pulse
        property real v: 1
        property SequentialAnimation anim: SequentialAnimation {
            running: n.micActive
            loops: Animation.Infinite
            NumberAnimation { target: pulse; property: "v"; from: 1; to: 0.35; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { target: pulse; property: "v"; from: 0.35; to: 1; duration: 900; easing.type: Easing.InOutSine }
            onStopped: pulse.v = 1
        }
    }
}
