package com.example.socialpulse

import android.content.Context

/**
 * Behavior engine that extracts features from raw data and detects phubbing.
 * Uses rule-based detection for MVP; can be replaced with ML later.
 */
class BehaviorEngine(
    private val context: Context,
    private val usageTracker: UsageTracker,
    private val dataStore: DataStore
) {

    /**
     * Extract a feature vector from current usage data.
     */
    fun extractFeatures(bluetoothDeviceCount: Int = 0): Map<String, Any> {
        val unlockCount = usageTracker.getUnlockCount(60)
        val avgSession = usageTracker.getAverageSessionDuration(60)
        val appSwitches = usageTracker.getAppSwitchCount(60)
        val notifTriggered = NotificationService.getNotificationTriggeredUnlockCount()

        val hour = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)

        return mapOf(
            "unlock_count_per_hour" to unlockCount,
            "avg_session_duration_ms" to avgSession,
            "app_switch_frequency" to appSwitches,
            "notification_triggered_unlocks" to notifTriggered,
            "bluetooth_device_count" to bluetoothDeviceCount,
            "time_of_day" to hour
        )
    }

    /**
     * Detect if phubbing is likely occurring.
     * Rule-based: high unlocks + short sessions + social context.
     */
    fun detectPhubbing(bluetoothDeviceCount: Int = 0): Map<String, Any> {
        val features = extractFeatures(bluetoothDeviceCount)

        val unlocks = (features["unlock_count_per_hour"] as? Number)?.toInt() ?: 0
        val avgSession = (features["avg_session_duration_ms"] as? Number)?.toLong() ?: 0L
        val btDevices = (features["bluetooth_device_count"] as? Number)?.toInt() ?: 0

        // Get baseline or use defaults
        val baseline = dataStore.getBaseline() ?: mapOf(
            "avg_unlocks_per_hour" to 5.0,
            "avg_session_ms" to 10000L,
            "avg_app_switches" to 8.0
        )

        val baselineUnlocks = (baseline["avg_unlocks_per_hour"] as? Number)?.toDouble() ?: 5.0

        // Rule-based detection
        val highUnlocks = unlocks > (baselineUnlocks * 1.5)
        val shortSessions = avgSession < 15_000 // Less than 15 seconds
        val socialContext = btDevices >= 3

        val isPhubbing = highUnlocks && shortSessions && socialContext
        val isDistracted = highUnlocks && shortSessions // Distracted even without social context

        // Determine severity
        val severity = when {
            isPhubbing -> "high"
            isDistracted -> "medium"
            highUnlocks -> "low"
            else -> "none"
        }

        // Determine context
        val detectedContext = when {
            socialContext -> "social"
            else -> "solo"
        }

        // Determine trigger type
        val triggerType = when {
            isPhubbing -> "phubbing"
            isDistracted -> "distraction"
            highUnlocks -> "attention_drift"
            else -> "normal"
        }

        // Log event if significant
        if (severity != "none") {
            dataStore.addPhubbingEvent(
                System.currentTimeMillis(),
                detectedContext,
                triggerType
            )
        }

        return mapOf(
            "is_phubbing" to isPhubbing,
            "is_distracted" to isDistracted,
            "severity" to severity,
            "context" to detectedContext,
            "trigger_type" to triggerType,
            "features" to features,
            "baseline_learning" to dataStore.isBaselineLearning()
        )
    }

    /**
     * Generate daily analysis summary.
     */
    fun getDailyAnalysis(): Map<String, Any> {
        val unlocks24h = usageTracker.getUnlockCount(1440)
        val avgSession = usageTracker.getAverageSessionDuration(1440)
        val appSwitches = usageTracker.getAppSwitchCount(1440)
        val phubbingEvents = dataStore.getPhubbingEventsToday()
        val sessions = usageTracker.getAppSessions(1440)

        // Find most distracting apps (most sessions, shortest duration)
        val appCounts = sessions.groupBy { it["app_name"] as String }
            .mapValues { it.value.size }
            .entries
            .sortedByDescending { it.value }
            .take(5)
            .map { mapOf("app" to it.key, "count" to it.value) }

        // Calculate presence score (inverse of phubbing)
        val presenceScore = if (unlocks24h > 0) {
            val phubbingRatio = phubbingEvents.size.toDouble() / unlocks24h
            ((1.0 - phubbingRatio.coerceAtMost(1.0)) * 100).toInt()
        } else {
            100
        }

        val analysis = mapOf(
            "total_unlocks" to unlocks24h,
            "avg_session_duration_ms" to avgSession,
            "app_switches" to appSwitches,
            "phubbing_events" to phubbingEvents.size,
            "presence_score" to presenceScore,
            "most_distracting_apps" to appCounts,
            "total_sessions" to sessions.size
        )

        dataStore.saveDailyAnalysis(analysis)

        // If in baseline learning period, save a sample
        if (dataStore.isBaselineLearning()) {
            dataStore.addDailyBaselineSample(unlocks24h, avgSession, appSwitches)
        } else if (dataStore.getBaselineStartDay() > 0 && !dataStore.isBaselineLearning()) {
            // Baseline learning complete — compute and save
            val computed = dataStore.computeBaseline()
            dataStore.saveBaseline(computed)
        }

        return analysis
    }

    /**
     * Start baseline learning if not already started.
     */
    fun startBaselineLearning() {
        dataStore.startBaselineLearning()
    }

    /**
     * Get baseline status.
     */
    fun getBaselineStatus(): Map<String, Any> {
        val startDay = dataStore.getBaselineStartDay()
        val isLearning = dataStore.isBaselineLearning()
        val baseline = dataStore.getBaseline()
        val samples = dataStore.getDailyBaselineSamples().size

        val daysElapsed = if (startDay > 0) {
            ((System.currentTimeMillis() - startDay) / (24 * 60 * 60 * 1000L)).toInt()
        } else 0

        return mapOf(
            "started" to (startDay > 0),
            "is_learning" to isLearning,
            "days_elapsed" to daysElapsed,
            "days_remaining" to (if (isLearning) (7 - daysElapsed).coerceAtLeast(0) else 0),
            "samples_collected" to samples,
            "baseline" to (baseline ?: emptyMap<String, Any>())
        )
    }
}
