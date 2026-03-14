package com.example.socialpulse

import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.socialpulse/backend"

    private lateinit var usageTracker: UsageTracker
    private lateinit var dataStore: DataStore
    private lateinit var nudgeManager: NudgeManager
    private lateinit var behaviorEngine: BehaviorEngine
    private lateinit var bluetoothScanner: BluetoothScanner

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize native services
        usageTracker = UsageTracker(this)
        dataStore = DataStore(this)
        nudgeManager = NudgeManager(this, dataStore)
        behaviorEngine = BehaviorEngine(this, usageTracker, dataStore)
        bluetoothScanner = BluetoothScanner(this)

        // Start baseline learning
        dataStore.startBaselineLearning()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {

                        // --- Permissions ---
                        "checkPermissions" -> {
                            result.success(mapOf(
                                "usage_stats" to hasUsageStatsPermission(),
                                "notification_listener" to isNotificationListenerEnabled(),
                                "bluetooth" to bluetoothScanner.isAvailable()
                            ))
                        }

                        "openUsageStatsSettings" -> {
                            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        }

                        "openNotificationListenerSettings" -> {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        }


                        // --- Usage Stats ---
                        "getUsageStats" -> {
                            if (!hasUsageStatsPermission()) {
                                result.success(mapOf("error" to "no_permission", "has_permission" to false))
                            } else {
                                result.success(usageTracker.getSummary())
                            }
                        }

                        // --- Bluetooth ---
                        "scanBluetooth" -> {
                            bluetoothScanner.scan { count ->
                                runOnUiThread {
                                    result.success(mapOf(
                                        "device_count" to count,
                                        "social_context" to if (count >= 3) "social" else "solo"
                                    ))
                                }
                            }
                        }

                        "getBluetoothDevices" -> {
                            result.success(mapOf(
                                "device_count" to bluetoothScanner.getLastScanCount(),
                                "social_context" to if (bluetoothScanner.getLastScanCount() >= 3) "social" else "solo"
                            ))
                        }

                        // --- Notifications ---
                        "getNotificationLog" -> {
                            result.success(mapOf(
                                "recent" to NotificationService.getRecentNotificationsList(),
                                "notification_triggered_unlocks" to NotificationService.getNotificationTriggeredUnlockCount(),
                                "listener_enabled" to isNotificationListenerEnabled()
                            ))
                        }

                        // --- Behavior Features ---
                        "getBehaviorFeatures" -> {
                            val btCount = call.argument<Int>("bluetooth_count") ?: bluetoothScanner.getLastScanCount()
                            result.success(behaviorEngine.extractFeatures(btCount))
                        }

                        // --- Phubbing Detection ---
                        "detectPhubbing" -> {
                            val btCount = call.argument<Int>("bluetooth_count") ?: bluetoothScanner.getLastScanCount()
                            val detection = behaviorEngine.detectPhubbing(btCount)

                            // Auto-send nudge if phubbing detected
                            val isPhubbing = detection["is_phubbing"] as? Boolean ?: false
                            val isDistracted = detection["is_distracted"] as? Boolean ?: false
                            var nudgeSent = false

                            if (isPhubbing) {
                                nudgeSent = nudgeManager.sendNudge("social")
                            } else if (isDistracted) {
                                nudgeSent = nudgeManager.sendNudge("awareness")
                            }

                            val mutableResult = detection.toMutableMap()
                            mutableResult["nudge_sent"] = nudgeSent
                            result.success(mutableResult)
                        }

                        // --- Daily Analysis ---
                        "getDailyAnalysis" -> {
                            result.success(behaviorEngine.getDailyAnalysis())
                        }

                        // --- Baseline ---
                        "getBaselineStatus" -> {
                            result.success(behaviorEngine.getBaselineStatus())
                        }

                        "startBaseline" -> {
                            behaviorEngine.startBaselineLearning()
                            result.success(true)
                        }

                        // --- Nudge ---
                        "sendNudge" -> {
                            val type = call.argument<String>("type") ?: "awareness"
                            val sent = nudgeManager.sendNudge(type)
                            result.success(mapOf(
                                "sent" to sent,
                                "nudges_this_hour" to nudgeManager.getNudgeCountLastHour()
                            ))
                        }

                        // --- Phubbing Events ---
                        "getPhubbingEvents" -> {
                            result.success(mapOf(
                                "today" to dataStore.getPhubbingEventsToday(),
                                "all" to dataStore.getPhubbingEvents()
                            ))
                        }

                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("NATIVE_ERROR", e.message, e.stackTraceToString())
                }
            }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val cn = ComponentName(this, NotificationService::class.java)
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return flat != null && flat.contains(cn.flattenToString())
    }
}
