package com.example.socialpulse

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

/**
 * Local data store using SharedPreferences + Gson for JSON serialization.
 * Stores usage logs, notification logs, phubbing events, baseline, and daily analysis.
 */
class DataStore(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("presence_pulse_data", Context.MODE_PRIVATE)
    private val gson = Gson()

    // --- Notification Logs ---

    fun addNotificationLog(appName: String, timestamp: Long) {
        val logs = getNotificationLogs().toMutableList()
        logs.add(mapOf("app_name" to appName, "timestamp" to timestamp))
        // Keep last 200 entries
        val trimmed = if (logs.size > 200) logs.takeLast(200) else logs
        prefs.edit().putString("notification_logs", gson.toJson(trimmed)).apply()
    }

    fun getNotificationLogs(): List<Map<String, Any>> {
        val json = prefs.getString("notification_logs", "[]") ?: "[]"
        val type = object : TypeToken<List<Map<String, Any>>>() {}.type
        return gson.fromJson(json, type) ?: emptyList()
    }

    // --- Phubbing Events ---

    fun addPhubbingEvent(timestamp: Long, context: String, triggerType: String) {
        val events = getPhubbingEvents().toMutableList()
        events.add(mapOf(
            "timestamp" to timestamp,
            "context" to context,
            "trigger_type" to triggerType
        ))
        val trimmed = if (events.size > 500) events.takeLast(500) else events
        prefs.edit().putString("phubbing_events", gson.toJson(trimmed)).apply()
    }

    fun getPhubbingEvents(): List<Map<String, Any>> {
        val json = prefs.getString("phubbing_events", "[]") ?: "[]"
        val type = object : TypeToken<List<Map<String, Any>>>() {}.type
        return gson.fromJson(json, type) ?: emptyList()
    }

    fun getPhubbingEventsToday(): List<Map<String, Any>> {
        val dayStart = getDayStartMillis()
        return getPhubbingEvents().filter {
            val ts = (it["timestamp"] as? Number)?.toLong() ?: 0L
            ts >= dayStart
        }
    }

    // --- Baseline Data ---

    fun saveBaseline(data: Map<String, Any>) {
        prefs.edit().putString("baseline", gson.toJson(data)).apply()
    }

    fun getBaseline(): Map<String, Any>? {
        val json = prefs.getString("baseline", null) ?: return null
        val type = object : TypeToken<Map<String, Any>>() {}.type
        return gson.fromJson(json, type)
    }

    fun getBaselineStartDay(): Long {
        return prefs.getLong("baseline_start_day", 0L)
    }

    fun setBaselineStartDay(timestamp: Long) {
        prefs.edit().putLong("baseline_start_day", timestamp).apply()
    }

    fun isBaselineLearning(): Boolean {
        val startDay = getBaselineStartDay()
        if (startDay == 0L) return false
        val elapsed = System.currentTimeMillis() - startDay
        val daysPassed = elapsed / (24 * 60 * 60 * 1000L)
        return daysPassed < 7
    }

    fun startBaselineLearning() {
        if (getBaselineStartDay() == 0L) {
            setBaselineStartDay(System.currentTimeMillis())
        }
    }

    // --- Daily Baseline Samples ---

    fun addDailyBaselineSample(unlocks: Int, avgSession: Long, appSwitches: Int) {
        val samples = getDailyBaselineSamples().toMutableList()
        samples.add(mapOf(
            "unlocks" to unlocks,
            "avg_session" to avgSession,
            "app_switches" to appSwitches,
            "timestamp" to System.currentTimeMillis()
        ))
        prefs.edit().putString("baseline_samples", gson.toJson(samples)).apply()
    }

    fun getDailyBaselineSamples(): List<Map<String, Any>> {
        val json = prefs.getString("baseline_samples", "[]") ?: "[]"
        val type = object : TypeToken<List<Map<String, Any>>>() {}.type
        return gson.fromJson(json, type) ?: emptyList()
    }

    fun computeBaseline(): Map<String, Any> {
        val samples = getDailyBaselineSamples()
        if (samples.isEmpty()) {
            return mapOf(
                "avg_unlocks_per_hour" to 5.0,
                "avg_session_ms" to 10000L,
                "avg_app_switches" to 8.0
            )
        }
        val avgUnlocks = samples.mapNotNull { (it["unlocks"] as? Number)?.toDouble() }.average()
        val avgSession = samples.mapNotNull { (it["avg_session"] as? Number)?.toLong() }.average().toLong()
        val avgSwitches = samples.mapNotNull { (it["app_switches"] as? Number)?.toDouble() }.average()
        return mapOf(
            "avg_unlocks_per_hour" to avgUnlocks,
            "avg_session_ms" to avgSession,
            "avg_app_switches" to avgSwitches
        )
    }

    // --- Nudge Tracking ---

    fun getLastNudgeTimestamps(): List<Long> {
        val json = prefs.getString("nudge_timestamps", "[]") ?: "[]"
        val type = object : TypeToken<List<Long>>() {}.type
        return gson.fromJson(json, type) ?: emptyList()
    }

    fun addNudgeTimestamp(timestamp: Long) {
        val list = getLastNudgeTimestamps().toMutableList()
        list.add(timestamp)
        // Keep last hour only
        val oneHourAgo = System.currentTimeMillis() - 3_600_000
        val filtered = list.filter { it > oneHourAgo }
        prefs.edit().putString("nudge_timestamps", gson.toJson(filtered)).apply()
    }

    fun getNudgeCountLastHour(): Int {
        val oneHourAgo = System.currentTimeMillis() - 3_600_000
        return getLastNudgeTimestamps().count { it > oneHourAgo }
    }

    // --- Daily Analysis ---

    fun saveDailyAnalysis(data: Map<String, Any>) {
        prefs.edit().putString("daily_analysis_${getDayKey()}", gson.toJson(data)).apply()
    }

    fun getDailyAnalysis(): Map<String, Any>? {
        val json = prefs.getString("daily_analysis_${getDayKey()}", null) ?: return null
        val type = object : TypeToken<Map<String, Any>>() {}.type
        return gson.fromJson(json, type)
    }

    // --- Helpers ---

    private fun getDayStartMillis(): Long {
        val cal = java.util.Calendar.getInstance()
        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
        cal.set(java.util.Calendar.MINUTE, 0)
        cal.set(java.util.Calendar.SECOND, 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun getDayKey(): String {
        val sdf = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
        return sdf.format(java.util.Date())
    }
}
