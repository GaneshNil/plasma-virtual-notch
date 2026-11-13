import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "components" as Components

Item {
    id: card
    property var n // the notch PlasmoidItem

    implicitWidth: Kirigami.Units.gridUnit * 22
    implicitHeight: col.implicitHeight + Kirigami.Units.largeSpacing * 2.5
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.minimumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight

    // Active sliding card view: 0 = Stats, 1 = Media, 2 = Controls
    property int currentCardIndex: 0
    readonly property int totalCards: 3

    // Focus management for keyboard navigation
    focus: true
    Keys.forwardTo: [navHandler]

    Item {
        id: navHandler
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Left) {
                card.previousTab();
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                card.nextTab();
                event.accepted = true;
            } else if (event.key === Qt.Key_Home) {
                card.currentCardIndex = 0;
                event.accepted = true;
            } else if (event.key === Qt.Key_End) {
                card.currentCardIndex = card.totalCards - 1;
                event.accepted = true;
            } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                card.nextTab();
                event.accepted = true;
            }
        }
    }

    function nextTab() {
        if (currentCardIndex < totalCards - 1) currentCardIndex++;
        else currentCardIndex = 0;
    }

    function previousTab() {
        if (currentCardIndex > 0) currentCardIndex--;
        else currentCardIndex = totalCards - 1;
    }

    function fmtUptime(sec) {
        sec = Math.floor(sec);
        const d = Math.floor(sec / 86400), h = Math.floor(sec % 86400 / 3600), m = Math.floor(sec % 3600 / 60);
        return (d ? d + "d " : "") + h + "h " + m + "m";
    }

    Timer {
        id: clock
        property date now: new Date()
        interval: 1000; repeat: true; triggeredOnStart: true
        running: card.visible
        onTriggered: now = new Date()
    }

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: Kirigami.Units.largeSpacing * 1.5 }
        spacing: Kirigami.Units.mediumSpacing

        // Header: Clock, Date, and Mic pill
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 0
                Text { 
                    text: Qt.formatTime(clock.now, "hh:mm"); 
                    color: card.n.cText; 
                    font.family: card.n.monoFont; 
                    font.pixelSize: 26; 
                    font.weight: Font.DemiBold 
                }
                Text { 
                    text: Qt.formatDate(clock.now, "dddd, d MMMM"); 
                    color: card.n.cDim; 
                    font.pixelSize: 11 
                }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                radius: height / 2
                color: card.n.micActive ? Qt.rgba(1, 0.62, 0.26, 0.15) : "#14141c"
                implicitHeight: micRow.implicitHeight + 8
                implicitWidth: micRow.implicitWidth + 16
                Row {
                    id: micRow
                    anchors.centerIn: parent
                    spacing: 6
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7; height: 7; radius: 3.5
                        color: card.n.micActive ? card.n.cMic : card.n.cDim
                    }
                    Text {
                        text: card.n.micActive ? "Mic: " + card.n.micApps.join(", ") : "Mic off"
                        color: card.n.micActive ? card.n.cMic : card.n.cDim
                        font.pixelSize: 11; font.family: card.n.monoFont
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, Kirigami.Units.gridUnit * 8)
                    }
                }
            }
        }

        // =====================================================================
        // Dynamic Island Tab Navigation Header (Click + Keyboard Focus)
        // =====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Previous Button (<--)
                Rectangle {
                    width: 72; height: 26; radius: 13
                    color: "#181824"; border.color: "#28283c"; border.width: 1
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Kirigami.Icon { source: "go-previous-symbolic"; color: card.n.cText; Layout.preferredWidth: 12; Layout.preferredHeight: 12; isMask: true }
                        Text { text: "Previous"; color: card.n.cText; font.pixelSize: 10; font.weight: Font.Medium }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.previousTab()
                    }
                }

                Item { Layout.fillWidth: true }
                Text { text: "← / →"; color: card.n.cDim; font.pixelSize: 10; font.family: card.n.monoFont }
                Item { Layout.fillWidth: true }

                // Next Button (-->)
                Rectangle {
                    width: 58; height: 26; radius: 13
                    color: "#181824"; border.color: "#28283c"; border.width: 1
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "Next"; color: card.n.cText; font.pixelSize: 10; font.weight: Font.Medium }
                        Kirigami.Icon { source: "go-next-symbolic"; color: card.n.cText; Layout.preferredWidth: 12; Layout.preferredHeight: 12; isMask: true }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.nextTab()
                    }
                }
            }

            // Interactive Tabs (Stats | Media | Controls)
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 6

                Repeater {
                    model: [
                        { name: "Stats", icon: "utilities-system-monitor-symbolic" },
                        { name: "Media", icon: "media-playback-start-symbolic" },
                        { name: "Controls", icon: "preferences-system-symbolic" }
                    ]

                    Rectangle {
                        required property int index
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: card.currentCardIndex === index ? "#3b2654" : "#14141c"
                        border.color: card.currentCardIndex === index ? card.n.cAccent : "#1a1a24"
                        border.width: card.currentCardIndex === index ? 1.5 : 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Kirigami.Icon {
                                source: modelData.icon
                                color: card.currentCardIndex === index ? card.n.cAccent : card.n.cDim
                                Layout.preferredWidth: 14; Layout.preferredHeight: 14
                                isMask: true
                            }
                            Text {
                                text: modelData.name
                                color: card.currentCardIndex === index ? "#ffffff" : card.n.cDim
                                font.pixelSize: 12
                                font.weight: card.currentCardIndex === index ? Font.DemiBold : Font.Normal
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.currentCardIndex = index
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#1a1a24" }

        // =====================================================================
        // Swipeable / Sliding Card Container
        // =====================================================================
        Item {
            id: container
            Layout.fillWidth: true
            Layout.preferredHeight: {
                if (card.currentCardIndex === 0) return statsSection.implicitHeight;
                if (card.currentCardIndex === 1) return mediaSection.implicitHeight;
                return controlsSection.implicitHeight;
            }
            clip: true

            Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            // Mouse / Touch Gesture handler for left/right swipe
            MouseArea {
                anchors.fill: parent
                property real startX: 0
                onPressed: function(mouse) { startX = mouse.x }
                onReleased: function(mouse) {
                    var diff = mouse.x - startX;
                    if (diff > 40) card.previousTab();
                    else if (diff < -40) card.nextTab();
                }
            }

            // ----------------- CARD 0: SYSTEM MONITOR STATS -----------------
            ColumnLayout {
                id: statsSection
                width: parent.width
                opacity: card.currentCardIndex === 0 ? 1 : 0
                visible: opacity > 0
                x: card.currentCardIndex === 0 ? 0 : (card.currentCardIndex > 0 ? -container.width : container.width)
                Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
                spacing: 4

                StatRow { n: card.n; icon: "cpu-symbolic"; label: "CPU temp"
                    value: Math.round(card.n.v_cpuTemp) + " °C"; fraction: card.n.v_cpuTemp / 100; tint: card.n.tempColor(card.n.v_cpuTemp) }
                StatRow { n: card.n; icon: "cpu-symbolic"; label: "CPU load"
                    value: Math.round(card.n.v_cpuUse) + " %"; fraction: card.n.v_cpuUse / 100; tint: card.n.loadColor(card.n.v_cpuUse) }
                StatRow { n: card.n; icon: "video-display-symbolic"; label: "GPU temp"; visible: card.n.hasGpu
                    value: card.n.v_gpuTemp > 0 ? Math.round(card.n.v_gpuTemp) + " °C" : "sleeping"
                    fraction: card.n.v_gpuTemp / 100; tint: card.n.tempColor(card.n.v_gpuTemp) }
                StatRow { n: card.n; icon: "video-display-symbolic"; label: "GPU load"; visible: card.n.hasGpu
                    value: Math.round(card.n.v_gpuUse) + " %"; fraction: card.n.v_gpuUse / 100; tint: card.n.loadColor(card.n.v_gpuUse) }
                StatRow { n: card.n; icon: "memory-symbolic"; label: "RAM"
                    value: (card.n.v_ramUsed / 1073741824).toFixed(1) + " GB"; fraction: card.n.v_ramPct / 100; tint: card.n.loadColor(card.n.v_ramPct) }
                StatRow { n: card.n; icon: "drive-harddisk-symbolic"; label: "SSD temp"; visible: card.n.hasSsd
                    value: Math.round(card.n.v_ssdTemp) + " °C"; fraction: card.n.v_ssdTemp / 90; tint: card.n.tempColor(card.n.v_ssdTemp + 10) }
                StatRow { n: card.n; icon: "battery-symbolic"; label: "Battery"; visible: card.n.hasBattery && card.n.enableBattery
                    value: Math.round(card.n.v_batPct) + " %" + (card.n.v_batRate > 0.5 ? " ⚡" : "")
                    fraction: card.n.v_batPct / 100; tint: card.n.v_batPct < 20 ? card.n.cHot : card.n.cGood }
                StatRow { n: card.n; icon: "speedometer-symbolic"; label: "Fan"; visible: card.n.hasFan
                    value: Math.round(card.n.v_fan) + " rpm"; fraction: card.n.v_fan / 6000; tint: card.n.cAccent }
                StatRow { n: card.n; icon: "clock-symbolic"; label: "Uptime"
                    value: card.fmtUptime(card.n.v_uptime) }
            }

            // ----------------- CARD 1: MEDIA PLAYER EXPANDED -----------------
            ColumnLayout {
                id: mediaSection
                width: parent.width
                opacity: card.currentCardIndex === 1 ? 1 : 0
                visible: opacity > 0
                x: card.currentCardIndex === 1 ? 0 : (card.currentCardIndex < 1 ? container.width : -container.width)
                Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    // Large Album Artwork
                    Rectangle {
                        Layout.preferredWidth: 64; Layout.preferredHeight: 64; radius: 12; color: "#14141c"; clip: true
                        Image {
                            anchors.fill: parent
                            source: card.n.player && card.n.player.artUrl ? card.n.player.artUrl : ""
                            fillMode: Image.PreserveAspectCrop; asynchronous: true
                            sourceSize.width: 128; sourceSize.height: 128
                        }
                        Kirigami.Icon {
                            anchors.centerIn: parent; width: 28; height: 28
                            visible: !(card.n.player && card.n.player.artUrl)
                            source: "media-playback-start-symbolic"; color: card.n.cAccent; isMask: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { 
                            Layout.fillWidth: true
                            text: card.n.trackTitle || "No Media Playing"
                            color: card.n.cText; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight 
                        }
                        Text { 
                            Layout.fillWidth: true
                            text: card.n.trackArtist || "Unknown Artist"
                            color: card.n.cDim; font.pixelSize: 12; elide: Text.ElideRight 
                        }
                        Equalizer { 
                            n: card.n; active: card.n.playing && card.visible; opacity: card.n.playing ? 1 : 0.3 
                        }
                    }
                }

                // Playback Control Buttons
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 24

                    Rectangle {
                        width: 36; height: 36; radius: 18; color: "#1c1c28"
                        Kirigami.Icon { anchors.centerIn: parent; width: 18; height: 18; source: "media-skip-backward-symbolic"; color: card.n.cText; isMask: true }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (card.n.mediaModule) card.n.mediaModule.previousTrack()
                        }
                    }

                    Rectangle {
                        width: 44; height: 44; radius: 22; color: card.n.cPink
                        Kirigami.Icon { 
                            anchors.centerIn: parent; width: 22; height: 22
                            source: card.n.playing ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                            color: "#000000"; isMask: true 
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (card.n.mediaModule) card.n.mediaModule.playPause()
                        }
                    }

                    Rectangle {
                        width: 36; height: 36; radius: 18; color: "#1c1c28"
                        Kirigami.Icon { anchors.centerIn: parent; width: 18; height: 18; source: "media-skip-forward-symbolic"; color: card.n.cText; isMask: true }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (card.n.mediaModule) card.n.mediaModule.nextTrack()
                        }
                    }
                }
            }

            // ----------------- CARD 2: COMPLETE FUNCTIONAL CONTROLS -----------------
            ColumnLayout {
                id: controlsSection
                width: parent.width
                opacity: card.currentCardIndex === 2 ? 1 : 0
                visible: opacity > 0
                x: card.currentCardIndex === 2 ? 0 : container.width
                Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
                spacing: 8

                // Quick Toggle Row: Wi-Fi, Bluetooth, Docker Desktop
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // Wi-Fi Button & Status
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 8
                        color: (card.n.networkModule && card.n.networkModule.isConnected) ? "#1a2233" : "#14141c"
                        border.color: (card.n.networkModule && card.n.networkModule.isConnected) ? "#2b3c70" : "#1f1f2e"
                        border.width: 1

                        RowLayout {
                            anchors { fill: parent; margins: 6 }
                            Kirigami.Icon {
                                source: card.n.networkModule ? card.n.networkModule.iconName : "network-wireless-symbolic"
                                color: (card.n.networkModule && card.n.networkModule.isConnected) ? card.n.cCyan : card.n.cDim
                                Layout.preferredWidth: 16; Layout.preferredHeight: 16; isMask: true
                            }
                            Text {
                                Layout.fillWidth: true
                                text: (card.n.networkModule && card.n.networkModule.ssid !== "") ? card.n.networkModule.ssid : (card.n.networkModule && card.n.networkModule.wifiEnabled ? "Wi-Fi On" : "Wi-Fi Off")
                                color: card.n.cText; font.pixelSize: 11; font.weight: Font.Medium; elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (card.n.networkModule) card.n.networkModule.toggleWifi()
                        }
                    }

                    // Bluetooth Button & Status
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 8
                        color: (card.n.bluetoothModule && card.n.bluetoothModule.hasConnectedDevices) ? "#1a2233" : "#14141c"
                        border.color: (card.n.bluetoothModule && card.n.bluetoothModule.hasConnectedDevices) ? "#2b3c70" : "#1f1f2e"
                        border.width: 1

                        RowLayout {
                            anchors { fill: parent; margins: 6 }
                            Kirigami.Icon {
                                source: (card.n.bluetoothModule && card.n.bluetoothModule.hasConnectedDevices) ? "bluetooth-active-symbolic" : "bluetooth-symbolic"
                                color: (card.n.bluetoothModule && card.n.bluetoothModule.isOperational && !card.n.bluetoothModule.isBluetoothBlocked) ? card.n.cCyan : card.n.cDim
                                Layout.preferredWidth: 16; Layout.preferredHeight: 16; isMask: true
                            }
                            Text {
                                Layout.fillWidth: true
                                text: card.n.bluetoothModule ? card.n.bluetoothModule.statusText : "Bluetooth"
                                color: card.n.cText; font.pixelSize: 11; font.weight: Font.Medium; elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (card.n.bluetoothModule) card.n.bluetoothModule.toggleBluetooth()
                        }
                    }

                    // Docker Desktop Indicator
                    Rectangle {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 36; radius: 8
                        color: "#14141c"; border.color: "#1f1f2e"; border.width: 1
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            source: "applications-development"
                            color: card.n.cCyan
                            Layout.preferredWidth: 16; Layout.preferredHeight: 16
                            isMask: true
                        }
                    }
                }

                // Volume Scrub Row with Mute Button & Sink Name
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Audio: " + (card.n.audioModule ? card.n.audioModule.sinkName : "Output"); color: card.n.cDim; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: (card.n.audioModule ? card.n.audioModule.volume : 0) + "%"; color: card.n.cText; font.family: card.n.monoFont; font.pixelSize: 10 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Kirigami.Icon {
                            source: (card.n.audioModule && card.n.audioModule.muted) ? "audio-volume-muted-symbolic" : "audio-volume-high-symbolic"
                            color: card.n.cAccent; isMask: true
                            Layout.preferredWidth: 16; Layout.preferredHeight: 16
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (card.n.audioModule) card.n.audioModule.toggleMute()
                            }
                        }

                        Rectangle {
                            id: volTrack
                            Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: "#1a1a24"
                            Rectangle {
                                width: parent.width * ((card.n.audioModule ? card.n.audioModule.volume : 0) / 100)
                                height: parent.height; radius: 3
                                color: (card.n.audioModule && card.n.audioModule.muted) ? card.n.cDim : card.n.cAccent
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: function(mouse) {
                                    if (card.n.audioModule) {
                                        var pct = Math.round((mouse.x / volTrack.width) * 100);
                                        card.n.audioModule.setVolume(pct);
                                    }
                                }
                            }
                        }
                    }
                }

                // Brightness Scrub Row
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Display Brightness"; color: card.n.cDim; font.pixelSize: 10; Layout.fillWidth: true }
                        Text { text: (card.n.brightnessModule ? card.n.brightnessModule.brightness : 40) + "%"; color: card.n.cText; font.family: card.n.monoFont; font.pixelSize: 10 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Kirigami.Icon {
                            source: "brightness-high-symbolic"; color: card.n.cWarn; isMask: true
                            Layout.preferredWidth: 16; Layout.preferredHeight: 16
                        }

                        Rectangle {
                            id: brightTrack
                            Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: "#1a1a24"
                            Rectangle {
                                width: parent.width * ((card.n.brightnessModule ? card.n.brightnessModule.brightness : 40) / 100)
                                height: parent.height; radius: 3
                                color: card.n.cWarn
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: function(mouse) {
                                    if (card.n.brightnessModule) {
                                        var pct = Math.round((mouse.x / brightTrack.width) * 100);
                                        card.n.brightnessModule.setBrightness(pct);
                                    }
                                }
                            }
                        }
                    }
                }

                // Microphone Input Scrub Row
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Input: " + (card.n.audioModule ? card.n.audioModule.sourceName : "Mic"); color: card.n.cDim; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: (card.n.audioModule ? card.n.audioModule.micVolume : 0) + "%"; color: card.n.cText; font.family: card.n.monoFont; font.pixelSize: 10 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Kirigami.Icon {
                            source: (card.n.audioModule && card.n.audioModule.micMuted) ? "microphone-sensitivity-muted-symbolic" : "audio-input-microphone-symbolic"
                            color: card.n.cMic; isMask: true
                            Layout.preferredWidth: 16; Layout.preferredHeight: 16
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (card.n.audioModule) card.n.audioModule.toggleMicMute()
                            }
                        }

                        Rectangle {
                            id: micTrack
                            Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: "#1a1a24"
                            Rectangle {
                                width: parent.width * ((card.n.audioModule ? card.n.audioModule.micVolume : 0) / 100)
                                height: parent.height; radius: 3
                                color: (card.n.audioModule && card.n.audioModule.micMuted) ? card.n.cDim : card.n.cMic
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: function(mouse) {
                                    if (card.n.audioModule) {
                                        var pct = Math.round((mouse.x / micTrack.width) * 100);
                                        card.n.audioModule.setMicVolume(pct);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // Slide / Page Indicator Dots
        // =====================================================================
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    width: card.currentCardIndex === index ? 16 : 6
                    height: 6
                    radius: 3
                    color: card.currentCardIndex === index ? card.n.cAccent : "#2a2a3a"
                    Behavior on width { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 200 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.currentCardIndex = index
                    }
                }
            }
        }
    }
}
