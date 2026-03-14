package com.example.socialpulse

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receives BOOT_COMPLETED broadcast to restart baseline learning tracking.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Re-initialize data store to continue baseline learning
            val dataStore = DataStore(context)
            dataStore.startBaselineLearning()
        }
    }
}
