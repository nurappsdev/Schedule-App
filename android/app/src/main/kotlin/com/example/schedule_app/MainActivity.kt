package com.example.schedule_app

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "multi.parallel.channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalledApps" -> result.success(getInstalledApps())
                    "launchApp" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            val success = launchApp(this, packageName)
                            result.success(success)
                        } else {
                            result.error("INVALID_PACKAGE", "Package name is null", null)
                        }
                    }
                    "isOverlayPermissionGranted" -> {
                        result.success(if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            Settings.canDrawOverlays(this)
                        } else {
                            true
                        })
                    }
                    "requestOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                            startActivity(intent)
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun launchApp(context: Context, packageName: String): Boolean {
        val pm = context.packageManager
        val intent = pm.getLaunchIntentForPackage(packageName)
        
        return if (intent != null) {
            // Android 15 এবং Realme-র জন্য এই ফ্ল্যাগগুলো সবচাইতে কার্যকর
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            intent.addFlags(Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)

            try {
                context.startActivity(intent)
                true
            } catch (e: Exception) {
                println("Launch Error: ${e.message}")
                false
            }
        } else {
            false
        }
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val packages = pm.getInstalledApplications(0)
        val appList = mutableListOf<Map<String, String>>()

        for (app in packages) {
            val launchIntent = pm.getLaunchIntentForPackage(app.packageName)
            if (launchIntent != null) {
                val appName = pm.getApplicationLabel(app).toString()
                val packageName = app.packageName
                appList.add(mapOf("appName" to appName, "packageName" to packageName))
            }
        }
        return appList
    }
}
