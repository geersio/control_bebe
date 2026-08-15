package com.example.control_bebe

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import com.example.live_activities.LiveActivityManagerHolder
import org.json.JSONObject
import java.time.Instant
import java.time.format.DateTimeFormatter

object LactationTimerBridge {
    const val ACTIVITY_ID = "lactation_timer"
    private const val FLUTTER_TIMER_KEY = "flutter.control_bebe.lactation_timer.v1"
    private const val FLUTTER_PENDING_FEEDING_KEY =
        "flutter.control_bebe.lactation_pending_feeding.v1"
    private const val CONFIRM_SAVED = "saved"
    private const val SAVED_ANIMATION_MS = 1200L

    data class TimerState(
        val side: Int,
        val startedAt: Instant,
        val totalPausedMs: Long,
        val pausedAt: Instant?,
    ) {
        val isPaused: Boolean get() = pausedAt != null

        fun elapsedMs(now: Instant = Instant.now()): Long {
            var paused = totalPausedMs
            if (pausedAt != null) {
                paused += java.time.Duration.between(pausedAt, now).toMillis()
            }
            val raw = java.time.Duration.between(startedAt, now).toMillis() - paused
            return raw.coerceAtLeast(0)
        }
    }

    fun loadTimer(context: Context): TimerState? {
        val raw = prefs(context).getString(FLUTTER_TIMER_KEY, null) ?: return null

        return try {
            val json = JSONObject(raw)
            val startedAt = parseInstant(json.getString("startedAt"))
            val pausedAt = if (json.has("pausedAt") && !json.isNull("pausedAt")) {
                parseInstant(json.getString("pausedAt"))
            } else {
                null
            }
            TimerState(
                side = json.optInt("side", 0),
                startedAt = startedAt,
                totalPausedMs = json.optLong("totalPausedMs", 0L),
                pausedAt = pausedAt,
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    fun saveTimer(context: Context, timer: TimerState) {
        val json = JSONObject()
            .put("side", timer.side)
            .put("startedAt", timer.startedAt.toString())
            .put("startedAtMs", timer.startedAt.toEpochMilli())
            .put("totalPausedMs", timer.totalPausedMs)
        if (timer.pausedAt != null) {
            json.put("pausedAt", timer.pausedAt.toString())
            json.put("pausedAtMs", timer.pausedAt.toEpochMilli())
        }
        prefs(context).edit().putString(FLUTTER_TIMER_KEY, json.toString()).apply()
    }

    fun clearTimer(context: Context) {
        prefs(context).edit().remove(FLUTTER_TIMER_KEY).apply()
    }

    private fun queuePendingFeedingAdd(
        context: Context,
        id: Long,
        type: Int,
        startedAt: Instant,
        durationSeconds: Int,
    ) {
        val payload = JSONObject()
            .put("id", id)
            .put("type", type)
            .put("dateTimeMs", startedAt.toEpochMilli())
            .put("durationSeconds", durationSeconds)
        val entry = JSONObject()
            .put("kind", "feeding_add")
            .put("payload", payload)
            .put("attempts", 0)
            .put("nextAfterMs", 0)
        prefs(context).edit()
            .putString(FLUTTER_PENDING_FEEDING_KEY, entry.toString())
            .apply()
    }

    fun pause(context: Context) {
        val timer = loadTimer(context) ?: return
        if (timer.isPaused) return
        saveTimer(context, timer.copy(pausedAt = Instant.now()))
        updateNotification(context, confirmPhase = null)
        notifyFlutter("pause")
    }

    fun resume(context: Context) {
        val timer = loadTimer(context) ?: return
        val pausedAt = timer.pausedAt ?: return
        val extra = java.time.Duration.between(pausedAt, Instant.now()).toMillis()
        saveTimer(
            context,
            timer.copy(
                totalPausedMs = timer.totalPausedMs + extra,
                pausedAt = null,
            ),
        )
        updateNotification(context, confirmPhase = null)
        notifyFlutter("resume")
    }

    fun stopWithCelebration(context: Context) {
        val timer = loadTimer(context) ?: return
        val durationSec = (timer.elapsedMs() / 1000).coerceAtLeast(1)
        val feedingType = if (timer.side == 0) 0 else 1
        val recordId = System.currentTimeMillis() * 1000
        queuePendingFeedingAdd(context, recordId, feedingType, timer.startedAt, durationSec.toInt())
        clearTimer(context)
        playSavedHaptic(context)
        updateNotification(context, timerSnapshot = timer, confirmPhase = CONFIRM_SAVED)
        notifyFlutter("stop")
        Handler(Looper.getMainLooper()).postDelayed({
            LiveActivityManagerHolder.instance?.endActivity(ACTIVITY_ID, null, emptyMap())
        }, SAVED_ANIMATION_MS)
    }

    private fun playSavedHaptic(context: Context) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (!vibrator.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            vibrator.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(40)
        }
    }

    private fun notifyFlutter(action: String) {
        Handler(Looper.getMainLooper()).post {
            MainActivity.notifyLactationTimerChanged(action)
        }
    }

    private fun parseInstant(value: String): Instant =
        try {
            Instant.parse(value)
        } catch (_: Exception) {
            Instant.ofEpochMilli(
                java.time.ZonedDateTime.parse(value, DateTimeFormatter.ISO_DATE_TIME)
                    .toInstant()
                    .toEpochMilli(),
            )
        }

    private fun updateNotification(
        context: Context,
        timerSnapshot: TimerState? = null,
        confirmPhase: String?,
    ) {
        val manager = LiveActivityManagerHolder.instance as? CustomLiveActivityManager ?: return
        val timer = timerSnapshot ?: loadTimer(context)
        val data = buildNotificationData(context, timer, confirmPhase)
        manager.showUpdate(context, data)
    }

    fun buildNotificationData(
        context: Context,
        timer: TimerState?,
        confirmPhase: String?,
    ): Map<String, Any> {
        val title = context.getString(R.string.lactation_live_notification_title)
        if (timer == null) {
            return mapOf(
                "title" to title,
                "sideLabel" to "—",
                "startedAtMs" to System.currentTimeMillis(),
                "isPaused" to false,
                "totalPausedMs" to 0L,
                "frozenElapsedMs" to 0L,
                "confirmPhase" to (confirmPhase ?: "idle"),
                "savedLabel" to context.getString(R.string.lactation_saved_label),
            )
        }
        return mapOf(
            "title" to title,
            "sideLabel" to if (timer.side == 0) "Izquierdo" else "Derecho",
            "startedAtMs" to timer.startedAt.toEpochMilli(),
            "isPaused" to timer.isPaused,
            "totalPausedMs" to timer.totalPausedMs,
            "frozenElapsedMs" to timer.elapsedMs(),
            "confirmPhase" to (confirmPhase ?: "idle"),
            "savedLabel" to context.getString(R.string.lactation_saved_label),
        )
    }
}
