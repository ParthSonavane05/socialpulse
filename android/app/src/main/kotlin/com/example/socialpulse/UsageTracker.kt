package com.example.socialpulse

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build

class UsageTracker(private val context: Context) {

    private val usageStatsManager =
        context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

    /**
     * Check if usage stats permission is granted.
     */
    fun hasPermission(): Boolean {
        val now = System.currentTimeMillis()
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, now - 60_000, now
        )
        return stats != null && stats.isNotEmpty()
    }

    /**
     * Get unlock count (MOVE_TO_FOREGROUND events) in the last [minutes] minutes.
     */
    fun getUnlockCount(minutes: Int = 60): Int {
        val now = System.currentTimeMillis()
        val startTime = now - (minutes * 60 * 1000L)
        val events = usageStatsManager.queryEvents(startTime, now)
        var count = 0
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                count++
            }
        }
        return count
    }

    /**
     * Get app usage sessions in the last [minutes] minutes.
     * Returns list of maps with: app_name, start_time, end_time, duration.
     */
    fun getAppSessions(minutes: Int = 60): List<Map<String, Any>> {
        val now = System.currentTimeMillis()
        val startTime = now - (minutes * 60 * 1000L)
        val events = usageStatsManager.queryEvents(startTime, now)
        val event = UsageEvents.Event()

        val sessions = mutableListOf<Map<String, Any>>()
        val activeApps = mutableMapOf<String, Long>() // packageName -> foregroundTime

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            when (event.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    activeApps[event.packageName] = event.timeStamp
                }
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    val fgTime = activeApps.remove(event.packageName)
                    if (fgTime != null) {
                        val duration = event.timeStamp - fgTime
                        if (duration > 500) { // Ignore sub-second blips
                            sessions.add(mapOf(
                                "app_name" to event.packageName,
                                "start_time" to fgTime,
                                "end_time" to event.timeStamp,
                                "duration" to duration
                            ))
                        }
                    }
                }
            }
        }
        return sessions
    }

    /**
     * Get app switch count in the last [minutes] minutes.
     */
    fun getAppSwitchCount(minutes: Int = 60): Int {
        val now = System.currentTimeMillis()
        val startTime = now - (minutes * 60 * 1000L)
        val events = usageStatsManager.queryEvents(startTime, now)
        val event = UsageEvents.Event()
        var count = 0
        var lastPackage: String? = null
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                if (lastPackage != null && lastPackage != event.packageName) {
                    count++
                }
                lastPackage = event.packageName
            }
        }
        return count
    }

    /**
     * Get average session duration in milliseconds.
     */
    fun getAverageSessionDuration(minutes: Int = 60): Long {
        val sessions = getAppSessions(minutes)
        if (sessions.isEmpty()) return 0
        val totalDuration = sessions.sumOf { (it["duration"] as Long) }
        return totalDuration / sessions.size
    }

    /**
     * Returns a summary map for the platform channel.
     */
    fun getSummary(): Map<String, Any> {
        return mapOf(
            "has_permission" to hasPermission(),
            "unlock_count_1h" to getUnlockCount(60),
            "unlock_count_24h" to getUnlockCount(1440),
            "app_switch_count_1h" to getAppSwitchCount(60),
            "avg_session_ms" to getAverageSessionDuration(60),
            "session_count_1h" to getAppSessions(60).size
        )
    }
}
