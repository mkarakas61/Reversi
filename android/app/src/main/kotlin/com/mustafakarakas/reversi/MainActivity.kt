package com.mustafakarakas.reversi

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val ringerChannelName = "com.mustafakarakas.reversi/ringer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
}
