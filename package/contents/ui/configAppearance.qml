import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_backgroundColor: bgColorField.text
    property alias cfg_accentColor: accentColorField.text
    property alias cfg_musicAccentColor: musicAccentColorField.text
    property alias cfg_micAccentColor: micAccentColorField.text
    property alias cfg_rimGlowEnabled: rimGlowCheck.checked
    property alias cfg_customBackgroundOpacity: opacitySlider.value

    QQC2.CheckBox {
        id: rimGlowCheck
        Kirigami.FormData.label: "Dynamic Rim Lighting & Glow:"
        text: "Enable reactive border glow"
    }

    QQC2.Slider {
        id: opacitySlider
        Kirigami.FormData.label: "Background Opacity:"
        from: 0.2; to: 1.0; stepSize: 0.05
    }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Color Palette (Hex Codes)" }

    QQC2.TextField {
        id: bgColorField
        Kirigami.FormData.label: "Background Color:"
        placeholderText: "#000000"
    }

    QQC2.TextField {
        id: accentColorField
        Kirigami.FormData.label: "Accent Color (Idle):"
        placeholderText: "#c77dff"
    }

    QQC2.TextField {
        id: musicAccentColorField
        Kirigami.FormData.label: "Music Accent Color:"
        placeholderText: "#ff8fd8"
    }

    QQC2.TextField {
        id: micAccentColorField
        Kirigami.FormData.label: "Microphone Accent Color:"
        placeholderText: "#ff9f43"
    }
}
