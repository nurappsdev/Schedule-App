package com.example.schedule_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import androidx.core.app.NotificationCompat

class AppLauncherReceiver : BroadcastReceiver() {
    companion object {
        const val TAG = "AppLauncherReceiver"
        const val ACTION_LAUNCH_APP = "com.example.schedule_app.ACTION_LAUNCH_APP"
        const val EXTRA_PACKAGE_NAME = "extra_package_name"
        const val CHANNEL_ID = "app_launcher_channel"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_LAUNCH_APP) {
            val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME)
            val alarmId = intent.getIntExtra("alarm_id", -1)
            
            Log.d(TAG, "🔔 Received launch request for: $packageName (ID: $alarmId)")
            
            if (packageName != null) {
                // ১. সরাসরি লঞ্চ করার চেষ্টা
                val success = launchApp(context, packageName)
                
                // ২. যদি সরাসরি লঞ্চ না হয় (Android 10+ background restriction), তবে নোটিফিকেশন দেখানো
                if (!success) {
                    showLaunchNotification(context, packageName, alarmId)
                }
                
                // কাজ শেষ হলে প্রিফারেন্স থেকে রিমুভ করা
                if (alarmId != -1) {
                    val prefs = context.getSharedPreferences("native_schedules", Context.MODE_PRIVATE)
                    prefs.edit().remove("schedule_$alarmId").apply()
                }
            }
        }
    }

    private fun showLaunchNotification(context: Context, packageName: String, alarmId: Int) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "App Launcher", NotificationManager.IMPORTANCE_HIGH)
            nm.createNotificationChannel(channel)
        }

        val pm = context.packageManager
        val appName = try {
            val ai = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(ai).toString()
        } catch (e: Exception) { packageName }

        val launchIntent = pm.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            context,
            alarmId + 1000,
            launchIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Scheduled Launch: $appName")
            .setContentText("Tap to open the app now.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pendingIntent, true) // লক স্ক্রিনেও কাজ করবে
            .setContentIntent(pendingIntent)

        nm.notify(alarmId, builder.build())
    }

    private fun launchApp(context: Context, packageName: String): Boolean {
        val pm = context.packageManager
        val launchIntent = pm.getLaunchIntentForPackage(packageName)
        
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)

            return try {
                context.startActivity(launchIntent)
                Log.d(TAG, "🚀 Successfully launched app: $packageName")
                true
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to launch app: ${e.message}")
                false
            }
        } else {
            Log.e(TAG, "❌ Launch intent is null for: $packageName")
            return false
        }
    }
}
