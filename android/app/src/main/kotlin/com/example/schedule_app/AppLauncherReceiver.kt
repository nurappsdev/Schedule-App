package com.example.schedule_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log

class AppLauncherReceiver : BroadcastReceiver() {
    companion object {
        const val TAG = "AppLauncherReceiver"
        const val ACTION_LAUNCH_APP = "com.example.schedule_app.ACTION_LAUNCH_APP"
        const val EXTRA_PACKAGE_NAME = "extra_package_name"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_LAUNCH_APP) {
            val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME)
            Log.d(TAG, "🔔 Received launch request for: $packageName")
            
            if (packageName != null) {
                launchApp(context, packageName)
            }
        }
    }

    private fun launchApp(context: Context, packageName: String) {
        val pm = context.packageManager
        val launchIntent = pm.getLaunchIntentForPackage(packageName)
        
        if (launchIntent != null) {
            // অ্যান্ড্রয়েড ১০+ এর জন্য ব্যাকগ্রাউন্ডে অ্যাপ ওপেন করার সময় কিছু সীমাবদ্ধতা থাকে।
            // "Display over other apps" পারমিশন থাকলে সেটা বাইপাস করা যায়।
            
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)

            try {
                context.startActivity(launchIntent)
                Log.d(TAG, "🚀 Successfully launched app: $packageName")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to launch app: ${e.message}")
                
                // যদি সাধারণ লঞ্চ ফেল করে, তবে অল্টারনেটিভ ট্রাই করতে পারি
                // যেমন ড্র-ওভার-লে পারমিশন থাকলে ফুল স্ক্রিন ইনটেন্ট ইউজ করা
            }
        } else {
            Log.e(TAG, "❌ Launch intent is null for: $packageName")
        }
    }
}
