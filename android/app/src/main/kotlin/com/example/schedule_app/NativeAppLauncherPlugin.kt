package com.example.schedule_app

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import android.app.AlarmManager
import android.app.PendingIntent
import java.util.*

class NativeAppLauncherPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "multi.parallel.channel")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "launchApp" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    val success = launchApp(context, packageName)
                    result.success(success)
                } else {
                    result.error("INVALID_PACKAGE", "Package name is null", null)
                }
            }
            "scheduleAlarm" -> {
                val packageName = call.argument<String>("packageName")
                val alarmId = call.argument<Int>("alarmId")
                val timeMillis = call.argument<Long>("timeMillis")
                
                if (packageName != null && alarmId != null && timeMillis != null) {
                    val success = scheduleAlarm(context, packageName, alarmId, timeMillis)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing arguments for scheduleAlarm", null)
                }
            }
            "cancelAlarm" -> {
                val alarmId = call.argument<Int>("alarmId")
                if (alarmId != null) {
                    cancelAlarm(context, alarmId)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing alarmId", null)
                }
            }
            "triggerLaunchBroadcast" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    val intent = Intent(context, AppLauncherReceiver::class.java).apply {
                        action = AppLauncherReceiver.ACTION_LAUNCH_APP
                        putExtra(AppLauncherReceiver.EXTRA_PACKAGE_NAME, packageName)
                    }
                    context.sendBroadcast(intent)
                    result.success(true)
                } else {
                    result.error("INVALID_PACKAGE", "Package name is null", null)
                }
            }
            "isOverlayPermissionGranted" -> {
                result.success(if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    Settings.canDrawOverlays(context)
                } else {
                    true
                })
            }
            "getInstalledApps" -> {
                result.success(getInstalledApps())
            }
            else -> result.notImplemented()
        }
    }

    fun scheduleAlarmFromBoot(context: Context, packageName: String, alarmId: Int, timeMillis: Long): Boolean {
        return scheduleAlarm(context, packageName, alarmId, timeMillis)
    }

    private fun scheduleAlarm(context: Context, packageName: String, alarmId: Int, timeMillis: Long): Boolean {
        // ১. সেভ করে রাখা (রিবুটের পর রিশিডিউল করার জন্য)
        saveSchedule(context, alarmId, packageName, timeMillis)

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AppLauncherReceiver::class.java).apply {
            action = AppLauncherReceiver.ACTION_LAUNCH_APP
            putExtra(AppLauncherReceiver.EXTRA_PACKAGE_NAME, packageName)
            // রিসিভার যাতে জানে এটা কোন আইডি
            putExtra("alarm_id", alarmId)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
                } else {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
            }
            return true
        } catch (e: Exception) {
            return false
        }
    }

    private fun cancelAlarm(context: Context, alarmId: Int) {
        // ১. সেভড ডেটা থেকে রিমুভ করা
        removeSchedule(context, alarmId)

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AppLauncherReceiver::class.java).apply {
            action = AppLauncherReceiver.ACTION_LAUNCH_APP
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )
        alarmManager.cancel(pendingIntent)
    }

    private fun saveSchedule(context: Context, alarmId: Int, packageName: String, timeMillis: Long) {
        val prefs = context.getSharedPreferences("native_schedules", Context.MODE_PRIVATE)
        prefs.edit().putString("schedule_$alarmId", "$packageName|$timeMillis").apply()
    }

    private fun removeSchedule(context: Context, alarmId: Int) {
        val prefs = context.getSharedPreferences("native_schedules", Context.MODE_PRIVATE)
        prefs.edit().remove("schedule_$alarmId").apply()
    }

    // এই ফাংশনটি BootReceiver থেকে কল করা হবে
    fun rescheduleAll(context: Context) {
        val prefs = context.getSharedPreferences("native_schedules", Context.MODE_PRIVATE)
        val allSchedules = prefs.all
        for ((key, value) in allSchedules) {
            if (key.startsWith("schedule_")) {
                try {
                    val alarmId = key.replace("schedule_", "").toInt()
                    val data = (value as String).split("|")
                    val packageName = data[0]
                    val timeMillis = data[1].toLong()

                    if (timeMillis > System.currentTimeMillis()) {
                        scheduleAlarm(context, packageName, alarmId, timeMillis)
                    } else {
                        removeSchedule(context, alarmId)
                    }
                } catch (e: Exception) { }
            }
        }
    }

    private fun launchApp(context: Context, packageName: String): Boolean {
        val pm = context.packageManager
        val intent = pm.getLaunchIntentForPackage(packageName)
        
        return if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            intent.addFlags(Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)

            try {
                context.startActivity(intent)
                true
            } catch (e: Exception) {
                false
            }
        } else {
            false
        }
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = context.packageManager
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
