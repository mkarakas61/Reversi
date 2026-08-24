package com.mustafakarakas.reversi

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val ringerChannelName = "com.mustafakarakas.reversi/ringer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ringerChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRingerMode" -> {
                        val audioManager =
                            getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        // AudioManager.RINGER_MODE_SILENT = 0, VIBRATE = 1, NORMAL = 2.
                        result.success(audioManager.ringerMode)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Creates the channel the manifest names as FCM's default (REV-111).
     *
     * The manifest entry only *points* at an id — Android does not create a
     * channel from it, and a notification aimed at a channel that does not
     * exist lands in a system-made "Miscellaneous" one instead. Doing it here,
     * on every start, is the documented approach: creating a channel that
     * already exists is a no-op, and it must exist *before* the first
     * notification arrives rather than the first time the player opens a
     * screen that happens to ask for it.
     *
     * Anything the player changes afterwards (importance, sound, whether it is
     * on at all) is theirs — re-creating never overwrites it.
     */
    private fun createNotificationChannel() {
        // Channels arrived in Android 8; below that the manifest entry is
        // simply ignored and notifications behave as they always did.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            GENERAL_CHANNEL_ID,
            getString(R.string.notification_channel_general),
            // DEFAULT, not HIGH: none of what this app sends is worth taking
            // over the screen with a heads-up banner.
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = getString(R.string.notification_channel_general_desc)
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    private companion object {
        /** Must match `default_notification_channel_id` in AndroidManifest.xml. */
        const val GENERAL_CHANNEL_ID = "reversi_general"
    }
}
