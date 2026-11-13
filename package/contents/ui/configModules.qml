import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_enableMedia: mediaCheck.checked
    property alias cfg_enableMicrophone: micCheck.checked
    property alias cfg_enableNotifications: notifyCheck.checked
    property alias cfg_enableSystemMonitor: sysCheck.checked
    property alias cfg_enableAudio: audioCheck.checked
    property alias cfg_enableNetwork: netCheck.checked
    property alias cfg_enableBluetooth: btCheck.checked
    property alias cfg_enableBattery: batCheck.checked
    property alias cfg_enableWeather: weatherCheck.checked

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Active Features" }

    QQC2.CheckBox {
        id: mediaCheck
        Kirigami.FormData.label: "Media (MPRIS):"
        text: "Album artwork, track metadata & interactive controls"
    }

    QQC2.CheckBox {
        id: micCheck
        Kirigami.FormData.label: "Microphone Activity:"
        text: "PipeWire detection and active recording app indicators"
    }

    QQC2.CheckBox {
        id: notifyCheck
        Kirigami.FormData.label: "Notifications:"
        text: "KDE Plasma notification toasts and alerts"
    }

    QQC2.CheckBox {
        id: audioCheck
        Kirigami.FormData.label: "Audio Controls:"
        text: "Master volume slider and mute toggles"
    }

    QQC2.CheckBox {
        id: sysCheck
        Kirigami.FormData.label: "System Monitoring:"
        text: "CPU, GPU, RAM, Fan and SSD performance metrics"
    }

    QQC2.CheckBox {
        id: netCheck
        Kirigami.FormData.label: "Network (Wi-Fi):"
        text: "Connection state and network name"
    }

    QQC2.CheckBox {
        id: btCheck
        Kirigami.FormData.label: "Bluetooth:"
        text: "Bluetooth status and paired devices"
    }

    QQC2.CheckBox {
        id: batCheck
        Kirigami.FormData.label: "Battery & Power:"
        text: "Charging indicator and power levels"
    }

    QQC2.CheckBox {
        id: weatherCheck
        Kirigami.FormData.label: "Weather (Open-Meteo):"
        text: "Current weather conditions and temperature"
    }
}

