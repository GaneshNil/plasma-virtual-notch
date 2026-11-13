import QtQuick
import org.kde.notificationmanager as NotificationManager

/*
 * NotificationModule.qml
 * Integrates with KDE Plasma Notification Manager to display alerts in Dynamic Island.
 */
BaseModule {
    id: notifyMod
    moduleId: "notifications"
    priority: 3
    preferredAccentColor: host ? host.cCyan : "#5cf2ff"

    NotificationManager.NotificationsModel {
        id: notificationsModel
        showJobs: false
        showNotifications: true
        blacklistedApplications: []
    }

    readonly property int count: notificationsModel.count
    readonly property bool hasNotifications: count > 0

    // Capture incoming notification event
    Connections {
        target: notificationsModel
        function onRowsInserted(parent, first, last) {
            if (!notifyMod.moduleEnabled || !host || !host.eventQueue) return;
            var idx = notificationsModel.index(first, 0);
            var summary = notificationsModel.data(idx, NotificationManager.Notifications.SummaryRole) || "Notification";
            var body = notificationsModel.data(idx, NotificationManager.Notifications.BodyRole) || "";
            var text = summary + (body ? ": " + body : "");
            host.eventQueue.postEvent("notifications", text, 3, 4500, notifyMod.preferredAccentColor);
        }
    }
}
