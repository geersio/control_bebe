package com.example.control_bebe

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class LactationNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            ACTION_PAUSE -> LactationTimerBridge.pause(context.applicationContext)
            ACTION_RESUME -> LactationTimerBridge.resume(context.applicationContext)
            ACTION_STOP -> LactationTimerBridge.stopWithCelebration(context.applicationContext)
        }
    }

    companion object {
        const val ACTION_PAUSE = "com.controlbebe.lactation.PAUSE"
        const val ACTION_RESUME = "com.controlbebe.lactation.RESUME"
        const val ACTION_STOP = "com.controlbebe.lactation.STOP"
    }
}
