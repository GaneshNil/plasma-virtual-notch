import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_notchWidth: notchWidthSpin.value
    property alias cfg_notchHeight: notchHeightSpin.value
    property alias cfg_cardWidth: cardWidthSpin.value
    property alias cfg_filletRadius: filletSpin.value
    property alias cfg_notchCornerRadius: notchCornerSpin.value
    property alias cfg_cardCornerRadius: cardCornerSpin.value

    property alias cfg_dwellTimeMs: dwellSpin.value
    property alias cfg_activityDurationMs: activitySpin.value
    property alias cfg_slideAwayEnabled: slideAwayCheck.checked
    property alias cfg_weatherCity: cityField.text

    QQC2.SpinBox {
        id: notchWidthSpin
        Kirigami.FormData.label: "Notch Width (px):"
        from: 180; to: 500; stepSize: 5
    }

    QQC2.SpinBox {
        id: notchHeightSpin
        Kirigami.FormData.label: "Notch Height (px):"
        from: 24; to: 60; stepSize: 2
    }

    QQC2.SpinBox {
        id: cardWidthSpin
        Kirigami.FormData.label: "Expanded Card Width (px):"
        from: 300; to: 700; stepSize: 10
    }

    QQC2.SpinBox {
        id: filletSpin
        Kirigami.FormData.label: "Top Shoulder Fillet (px):"
        from: 0; to: 25; stepSize: 1
    }

    QQC2.SpinBox {
        id: notchCornerSpin
        Kirigami.FormData.label: "Notch Corner Radius (px):"
        from: 4; to: 30; stepSize: 1
    }

    QQC2.SpinBox {
        id: cardCornerSpin
        Kirigami.FormData.label: "Card Corner Radius (px):"
        from: 10; to: 40; stepSize: 1
    }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Interaction & Timing" }

    QQC2.CheckBox {
        id: slideAwayCheck
        Kirigami.FormData.label: "Slide away when cursor approaches:"
        text: "Make underlying browser tabs accessible"
    }

    QQC2.SpinBox {
        id: dwellSpin
        Kirigami.FormData.label: "Top Edge Dwell Delay (ms):"
        from: 200; to: 2000; stepSize: 50
    }

    QQC2.SpinBox {
        id: activitySpin
        Kirigami.FormData.label: "Activity Alert Duration (ms):"
        from: 1500; to: 10000; stepSize: 250
    }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Location" }

    QQC2.TextField {
        id: cityField
        Kirigami.FormData.label: "Weather City:"
        placeholderText: "e.g. Pune, Tokyo, London"
    }
}

