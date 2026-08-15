package com.example.control_bebe

import android.content.Intent
import android.net.Uri
import com.example.live_activities.LiveActivityManagerHolder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val NAV_CHANNEL = "com.controlbebe/lactation_navigation"
        private const val TIMER_CHANNEL = "com.controlbebe/lactation_timer"

        @Volatile
        var pendingOpenFeeding: Boolean = false

        @Volatile
        var lactationTimerChannel: MethodChannel? = null

        fun notifyLactationTimerChanged(action: String) {
            lactationTimerChannel?.invokeMethod(
                "timerChanged",
                mapOf("action" to action),
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        LiveActivityManagerHolder.instance = CustomLiveActivityManager(this)
        lactationTimerChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TIMER_CHANNEL,
        )
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NAV_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumePendingOpenFeeding" -> {
                        val pending = pendingOpenFeeding
                        pendingOpenFeeding = false
                        result.success(pending)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        captureFeedingIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (captureFeedingIntent(intent)) {
            notifyOpenFeeding()
        }
    }

    private fun captureFeedingIntent(intent: Intent?): Boolean {
        val data: Uri = intent?.data ?: return false
        if (data.scheme == "mibebe" && data.host == "feeding") {
            pendingOpenFeeding = true
            return true
        }
        return false
    }

    private fun notifyOpenFeeding() {
        val engine = flutterEngine ?: return
        MethodChannel(engine.dartExecutor.binaryMessenger, NAV_CHANNEL)
            .invokeMethod("openFeeding", null)
        pendingOpenFeeding = false
    }
}
