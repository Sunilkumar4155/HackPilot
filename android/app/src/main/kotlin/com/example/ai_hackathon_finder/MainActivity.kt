package com.example.ai_hackathon_finder

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "hackathon_hub/theme_settings",
        ).setMethodCallHandler { call, result ->
            val preferences = getSharedPreferences("hackathon_hub_theme", MODE_PRIVATE)
            when (call.method) {
                "read" -> result.success(preferences.getString("settings", null))
                "write" -> {
                    val value = call.argument<String>("value")
                    if (value == null) {
                        result.error("invalid_value", "Theme settings were empty.", null)
                    } else {
                        preferences.edit().putString("settings", value).apply()
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
