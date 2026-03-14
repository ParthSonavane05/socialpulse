package com.example.socialpulse

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.core.app.NotificationCompat

/**
 * Manages sending gentle nudge notifications with rate limiting.
 * Max 3 nudges per hour.
 */
class NudgeManager(private val context: Context, private val dataStore: DataStore) {

    companion object {
        const val CHANNEL_ID = "presence_pulse_nudges"
        const val CHANNEL_NAME = "Presence Nudges"
        const val MAX_NUDGES_PER_HOUR = 3

        val AWARENESS_NUDGES = listOf(
            "Stay present — someone around you might appreciate your attention.",
            "Take a moment and enjoy the conversation.",
            "Your phone has been checked frequently. Stay with the moment.",
            "Look up. Connect with the people around you.",
            "This moment won't come again. Be here fully.",
            "People around you matter. Take a mindful pause.",
            "Try staying phone-free for the next 15 minutes."
        )

        val SOCIAL_NUDGES = listOf(
            "Looks like you're in a group setting. Stay present!",
            "Social moment detected — enjoy the real connection.",
            "Your presence is a gift to those around you."
        )

        val REFLECTION_NUDGES = listOf(
            "Try staying phone-free for the next 15 minutes.",
            "Take a deep breath and be present.",
            "Challenge: Can you go 10 minutes without checking your phone?"
        )
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Gentle reminders to stay present"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 100, 50, 100) // Soft vibration
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    /**
     * Send a nudge notification if rate limit allows.
     * Returns true if nudge was sent, false if rate-limited.
     */
    fun sendNudge(type: String = "awareness"): Boolean {
        if (dataStore.getNudgeCountLastHour() >= MAX_NUDGES_PER_HOUR) {
            return false
        }

        val message = when (type) {
            "social" -> SOCIAL_NUDGES.random()
            "reflection" -> REFLECTION_NUDGES.random()
            else -> AWARENESS_NUDGES.random()
        }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("PresencePulse")
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        val manager = context.getSystemService(NotificationManager::class.java)
        val notifId = (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
        manager.notify(notifId, notification)

        dataStore.addNudgeTimestamp(System.currentTimeMillis())
        return true
    }

    /**
     * Get the current nudge count in the last hour.
     */
    fun getNudgeCountLastHour(): Int {
        return dataStore.getNudgeCountLastHour()
    }

    /**
     * Check if nudge can be sent (under rate limit).
     */
    fun canSendNudge(): Boolean {
        return dataStore.getNudgeCountLastHour() < MAX_NUDGES_PER_HOUR
    }
}
