package com.example.control_bebe

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.example.live_activities.LiveActivityManager
import java.math.BigInteger
import java.security.MessageDigest

class CustomLiveActivityManager(context: Context) : LiveActivityManager(context) {
    private val appContext: Context = context.applicationContext
    private val remoteViews = RemoteViews(appContext.packageName, R.layout.lactation_live_activity)

    private fun contentIntent(): PendingIntent = PendingIntent.getActivity(
        appContext,
        201,
        Intent(appContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            data = Uri.parse("mibebe://feeding")
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun broadcastIntent(action: String, requestCode: Int): PendingIntent =
        PendingIntent.getBroadcast(
            appContext,
            requestCode,
            Intent(appContext, LactationNotificationReceiver::class.java).apply {
                this.action = action
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun formatElapsed(ms: Long): String {
        val total = (ms / 1000).toInt()
        val h = total / 3600
        val m = (total % 3600) / 60
        val s = total % 60
        return if (h > 0) {
            String.format("%d:%02d:%02d", h, m, s)
        } else {
            String.format("%d:%02d", m, s)
        }
    }

    private fun notificationId(): Int {
        val digest = MessageDigest.getInstance("SHA-256")
            .digest(LactationTimerBridge.ACTIVITY_ID.toByteArray())
        return BigInteger(digest).abs().toInt()
    }

    fun showUpdate(context: Context, data: Map<String, Any>) {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.O) return
        val channel = data["liveActivityChannelName"] as? String
            ?: context.getString(R.string.lactation_live_notification_title)
        initialize(
            mapOf(
                "liveActivityChannelName" to channel,
                "liveActivityChannelDescription" to (data["sideLabel"] as? String ?: ""),
            ),
        )
        val builder = Notification.Builder(context, channel)
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        notificationManager.notify(
            null,
            notificationId(),
            buildNotification(builder, "update", data),
        )
    }

    override suspend fun buildNotification(
        notification: Notification.Builder,
        event: String,
        data: Map<String, Any>,
    ): Notification {
        val title = data["title"] as? String
            ?: appContext.getString(R.string.lactation_live_notification_title)
        val sideLabel = data["sideLabel"] as? String ?: "—"
        val startedAtMs = (data["startedAtMs"] as Number).toLong()
        val isPaused = data["isPaused"] as? Boolean ?: false
        val totalPausedMs = (data["totalPausedMs"] as? Number)?.toLong() ?: 0L
        val frozenElapsedMs = (data["frozenElapsedMs"] as? Number)?.toLong() ?: 0L
        val confirmPhase = data["confirmPhase"] as? String ?: "idle"

        remoteViews.setTextViewText(R.id.lactation_title, title)
        remoteViews.setTextViewText(R.id.lactation_side, sideLabel)

        val pausePath = if (isPaused) LactationNotificationReceiver.ACTION_RESUME
        else LactationNotificationReceiver.ACTION_PAUSE
        val stopping = confirmPhase == "saved"

        if (stopping) {
            remoteViews.setChronometer(
                R.id.lactation_chronometer,
                0,
                formatElapsed(frozenElapsedMs),
                false,
            )
        } else if (isPaused) {
            remoteViews.setChronometer(
                R.id.lactation_chronometer,
                0,
                formatElapsed(frozenElapsedMs),
                false,
            )
        } else {
            val adjustedStartMs = startedAtMs + totalPausedMs
            val elapsedRealtime = android.os.SystemClock.elapsedRealtime()
            val currentTimeMillis = System.currentTimeMillis()
            val base = elapsedRealtime - (currentTimeMillis - adjustedStartMs)
            remoteViews.setChronometer(R.id.lactation_chronometer, base, null, true)
        }

        remoteViews.setViewVisibility(R.id.lactation_btn_pause, View.VISIBLE)
        remoteViews.setImageViewResource(
            R.id.lactation_btn_pause,
            if (isPaused) android.R.drawable.ic_media_play
            else android.R.drawable.ic_media_pause,
        )
        if (stopping) {
            remoteViews.setInt(R.id.lactation_btn_pause, "setImageAlpha", 96)
            remoteViews.setOnClickPendingIntent(R.id.lactation_btn_pause, null)
        } else {
            remoteViews.setInt(R.id.lactation_btn_pause, "setImageAlpha", 255)
            remoteViews.setOnClickPendingIntent(
                R.id.lactation_btn_pause,
                broadcastIntent(pausePath, if (isPaused) 203 else 202),
            )
        }

        if (confirmPhase == "saved") {
            remoteViews.setViewVisibility(R.id.lactation_btn_stop, View.VISIBLE)
            remoteViews.setImageViewResource(
                R.id.lactation_btn_stop,
                android.R.drawable.checkbox_on_background,
            )
            remoteViews.setInt(
                R.id.lactation_stop_container,
                "setBackgroundResource",
                R.drawable.lactation_stop_saved_bg,
            )
            remoteViews.setOnClickPendingIntent(R.id.lactation_btn_stop, null)
            remoteViews.setOnClickPendingIntent(R.id.lactation_stop_container, null)
        } else {
            remoteViews.setViewVisibility(R.id.lactation_btn_stop, View.VISIBLE)
            remoteViews.setInt(R.id.lactation_btn_stop, "setImageAlpha", 255)
            remoteViews.setInt(
                R.id.lactation_stop_container,
                "setBackgroundResource",
                android.R.color.transparent,
            )
            remoteViews.setImageViewResource(
                R.id.lactation_btn_stop,
                android.R.drawable.ic_media_stop,
            )
            remoteViews.setInt(
                R.id.lactation_btn_stop,
                "setBackgroundResource",
                android.R.color.transparent,
            )
            remoteViews.setOnClickPendingIntent(
                R.id.lactation_btn_stop,
                broadcastIntent(LactationNotificationReceiver.ACTION_STOP, 204),
            )
        }

        return notification
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(confirmPhase == "idle")
            .setOnlyAlertOnce(true)
            .setContentIntent(contentIntent())
            .setContentTitle(title)
            .setContentText(sideLabel)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setPriority(Notification.PRIORITY_LOW)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .build()
    }
}
