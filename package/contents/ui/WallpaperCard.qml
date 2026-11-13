import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// WallpaperCard.qml
// Integrated Wallpaper Island Gallery matching rofi wallpaper-gallery.rasi
// Allows searching, previewing, and 1-click applying wallpapers + MaterialYou themes
Item {
    id: wallView
    property var n // Host PlasmoidItem

    implicitWidth: Kirigami.Units.gridUnit * 28 // 4-column wide layout
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 12

        // Top Search Bar (Styled exactly like wallpaper-gallery.rasi)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 18
            color: "#181824cc"
            border.color: searchInput.activeFocus ? wallView.n.cAccent : "#28283c"
            border.width: 1.5

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 12 }
                spacing: 10

                Text {
                    text: "Wallpapers"
                    color: wallView.n.cAccent || "#a78bfa"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Rectangle {
                    width: 1; height: 16
                    color: "#28283c"
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: "#cdd6f4"
                    font.pixelSize: 11
                    selectByMouse: true
                    clip: true

                    Text {
                        text: "Search wallpaper..."
                        color: "#6c7086"
                        font.pixelSize: 11
                        visible: !searchInput.text && !searchInput.activeFocus
                    }

                    onTextChanged: {
                        if (wallView.n && wallView.n.backendBridge) {
                            wallView.n.backendBridge.wallpaperSearch = searchInput.text;
                        }
                    }
                }

                // Clear Search Button
                Rectangle {
                    visible: searchInput.text.length > 0
                    width: 20; height: 20; radius: 10
                    color: "#262638"
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#cdd6f4"
                        font.pixelSize: 10
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            if (wallView.n && wallView.n.backendBridge) {
                                wallView.n.backendBridge.wallpaperSearch = "";
                            }
                        }
                    }
                }
            }
        }

        // Wallpaper Grid View (4 columns, scrollable)
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 230
            clip: true

            Flickable {
                id: flick
                anchors.fill: parent
                contentHeight: flowGrid.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                clip: true

                Flow {
                    id: flowGrid
                    width: flick.width
                    spacing: 10

                    readonly property var items: (wallView.n && wallView.n.backendBridge) ? wallView.n.backendBridge.filteredWallpapers : []
                    readonly property int itemWidth: Math.floor((width - (spacing * 3) - 2) / 4)

                    Repeater {
                        model: flowGrid.items

                        Rectangle {
                            required property var modelData
                            width: flowGrid.itemWidth
                            height: 102
                            radius: 14

                            readonly property bool isCurrent: (wallView.n && wallView.n.backendBridge && wallView.n.backendBridge.currentWallpaper === modelData.path)
                            readonly property bool isHovered: itemMouse.containsMouse

                            color: isCurrent ? "#262638ee" : (isHovered ? "#202030cc" : "#16162299")
                            border.color: isCurrent ? (wallView.n.cAccent || "#a78bfa") : (isHovered ? Qt.rgba(0.65, 0.54, 0.98, 0.5) : "transparent")
                            border.width: isCurrent ? 2 : (isHovered ? 1.5 : 0)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            ColumnLayout {
                                anchors { fill: parent; margins: 6 }
                                spacing: 4

                                // Thumbnail Container
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 10
                                    color: "#0e0e16"
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: modelData.url
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                        sourceSize.width: 240
                                        sourceSize.height: 140
                                    }

                                    // Active Checkmark Badge
                                    Rectangle {
                                        visible: isCurrent
                                        anchors { top: parent.top; right: parent.right; margins: 4 }
                                        width: 18; height: 18; radius: 9
                                        color: wallView.n.cAccent || "#a78bfa"
                                        Kirigami.Icon {
                                            anchors.centerIn: parent
                                            source: "checkmark"
                                            color: "#ffffff"
                                            width: 11; height: 11
                                        }
                                    }
                                }

                                // Wallpaper Name Label
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.name
                                    color: isCurrent ? "#ffffff" : "#cdd6f4"
                                    font.pixelSize: 11
                                    font.weight: isCurrent ? Font.Bold : Font.Medium
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (wallView.n && wallView.n.backendBridge) {
                                        wallView.n.backendBridge.setWallpaper(modelData.path);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Scroll indicator if content overflows
            Rectangle {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: 3; radius: 1.5
                color: "#28283c"
                visible: flick.contentHeight > flick.height

                Rectangle {
                    width: parent.width
                    height: Math.max(20, (flick.height / flick.contentHeight) * flick.height)
                    y: (flick.contentY / (flick.contentHeight - flick.height)) * (flick.height - height)
                    radius: 1.5
                    color: wallView.n.cAccent || "#a78bfa"
                }
            }

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                visible: flowGrid.items.length === 0
                spacing: 8
                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    source: "edit-find-symbolic"
                    color: "#6c7086"
                    width: 32; height: 32
                }
                Text {
                    text: searchInput.text ? "No wallpapers matching \"" + searchInput.text + "\"" : "Loading wallpapers..."
                    color: "#6c7086"
                    font.pixelSize: 12
                }
            }
        }

        // Subtitle / Helper Tip
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                text: "Click any wallpaper to apply and auto-generate MaterialYou palette."
                color: "#6c7086"
                font.pixelSize: 10
                Layout.fillWidth: true
            }
            Text {
                text: ((wallView.n && wallView.n.backendBridge) ? wallView.n.backendBridge.wallpapers.length : 0) + " wallpapers"
                color: wallView.n.cAccent || "#a78bfa"
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }
    }
}

