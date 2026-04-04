package com.example.schedule_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // NativeAppLauncherPlugin রেজিস্টার করা হচ্ছে
        flutterEngine.plugins.add(NativeAppLauncherPlugin())
    }
}
