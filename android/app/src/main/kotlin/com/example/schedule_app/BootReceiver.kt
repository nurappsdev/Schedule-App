package com.example.schedule_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            Log.d("BootReceiver", "🚀 Device rebooted. Rescheduling all native alarms...")
            
            // NativeAppLauncherPlugin এর ইন্সট্যান্স ছাড়াই rescheduleAll কল করা যাবে যদি সেটা static বা companion হয়।
            // অথবা আমরা সরাসরি SharedPreferences রিড করে এখানেও লজিক লিখতে পারি।
            // যেহেতু NativeAppLauncherPlugin এ অলরেডি মেথড আছে, আমি সেটার লজিক এখানে ব্যবহার করছি।
            
            rescheduleAll(context)
        }
    }

    private fun rescheduleAll(context: Context) {
        val prefs = context.getSharedPreferences("native_schedules", Context.MODE_PRIVATE)
        val allSchedules = prefs.all
        val plugin = NativeAppLauncherPlugin() // ইন্সট্যান্স তৈরি করে কল করা নিরাপদ
        
        for ((key, value) in allSchedules) {
            if (key.startsWith("schedule_")) {
                try {
                    val alarmId = key.replace("schedule_", "").toInt()
                    val data = (value as String).split("|")
                    val packageName = data[0]
                    val timeMillis = data[1].toLong()

                    if (timeMillis > System.currentTimeMillis()) {
                        Log.d("BootReceiver", "⏰ Rescheduling alarm $alarmId for $packageName")
                        // এখানে সরাসরি কোড ডুপ্লিকেট করছি যাতে প্লাগিন এর জটিলতা এড়ানো যায়
                        plugin.scheduleAlarmFromBoot(context, packageName, alarmId, timeMillis)
                    } else {
                        prefs.edit().remove(key).apply()
                    }
                } catch (e: Exception) {
                    Log.e("BootReceiver", "Error rescheduling: ${e.message}")
                }
            }
        }
    }
}
