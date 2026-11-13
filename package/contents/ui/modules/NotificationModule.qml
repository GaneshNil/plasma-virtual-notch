import QtQuick
import org.kde.notificationmanager as NotificationManager

/*
 * NotificationModule.qml
 * Full two-way KDE Plasma Notification integration.
 */
BaseModule {
    id: notifyMod
    moduleId: "notifications"
    priority: 3
    preferredAccentColor: host ? host.cCyan : "#5cf2ff"

    NotificationManager.Notifications {
        id: notificationsModel
        showJobs: false
        showNotifications: true
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

    function getRecentNotifications() {
        var items = [];
        var maxItems = Math.min(notificationsModel.count, 6);
        for (var i = 0; i < maxItems; i++) {
            var idx = notificationsModel.index(i, 0);
            var summary = notificationsModel.data(idx, NotificationManager.Notifications.SummaryRole) || "Notification";
            var body = notificationsModel.data(idx, NotificationManager.Notifications.BodyRole) || "";
            var app = notificationsModel.data(idx, NotificationManager.Notifications.ApplicationNameRole) || "System";
            items.push({ id: i, summary: summary, body: body, app: app });
        }
        return items;
    }
}
