package com.example.socialpulse

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Listens for incoming notifications and logs them to DataStore.
 * This service must be enabled by the user in Settings → Notification Access.
 */
class NotificationService : NotificationListenerService() {

    companion object {
        /** Recent notifications accessible from MainActivity. */
        val recentNotifications = mutableListOf<Map<String, Any>>()
        private const val MAX_ENTRIES = 100

        /** Unlock timestamps for correlation with notification-triggered unlocks. */
        val recentUnlockTimestamps = mutableListOf<Long>()

        fun addUnlockTimestamp(ts: Long) {
            recentUnlockTimestamps.add(ts)
            if (recentUnlockTimestamps.size > 50) {
                recentUnlockTimestamps.removeAt(0)
            }
        }

        /**
         * Check if a notification at [notifTime] triggered a phone unlock
         * (unlock within 3 seconds of notification).
         */
        fun wasNotificationTriggeredUnlock(notifTime: Long): Boolean {
            return recentUnlockTimestamps.any { unlockTime ->
                unlockTime >= notifTime && (unlockTime - notifTime) <= 3000
            }
        }

        /**
         * Get count of notification-triggered unlocks from recent data.
         */
        fun getNotificationTriggeredUnlockCount(): Int {
            return recentNotifications.count { entry ->
                val ts = (entry["timestamp"] as? Number)?.toLong() ?: 0L
                wasNotificationTriggeredUnlock(ts)
            }
        }

        /**
         * Get recent notifications as serializable list for platform channel.
         */
        fun getRecentNotificationsList(): List<Map<String, Any>> {
            return recentNotifications.toList()
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return

        val packageName = sbn.packageName ?: "unknown"
        val timestamp = sbn.postTime

        val entry = mapOf<String, Any>(
            "app_name" to packageName,
            "timestamp" to timestamp
        )

        synchronized(recentNotifications) {
            recentNotifications.add(0, entry)
            if (recentNotifications.size > MAX_ENTRIES) {
                recentNotifications.removeAt(recentNotifications.size - 1)
            }
        }

        // Also persist to DataStore
        try {
            val dataStore = DataStore(applicationContext)
            dataStore.addNotificationLog(packageName, timestamp)
        } catch (_: Exception) {
            // Silently ignore if context not ready
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // No action needed for removed notifications
    }
}
