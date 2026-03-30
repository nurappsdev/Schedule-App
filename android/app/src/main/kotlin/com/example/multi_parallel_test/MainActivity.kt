package com.example.multi_parallel_test

import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {

    private val CHANNEL = "multi.parallel.channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                if (call.method == "getInstalledApps") {
                    result.success(getInstalledApps())
                }
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

                appList.add(
                    mapOf(
                        "appName" to appName,
                        "packageName" to packageName
                    )
                )
            }
        }

        return appList
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            val bitmap = Bitmap.createBitmap(
                drawable.intrinsicWidth,
                drawable.intrinsicHeight,
                Bitmap.Config.ARGB_8888
            )
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bitmap
        }

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        val byteArray = stream.toByteArray()
        return Base64.encodeToString(byteArray, Base64.DEFAULT)
    }
}