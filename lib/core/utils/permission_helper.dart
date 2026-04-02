import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionHelper {
  static Future<bool> requestAlarmPermissions() async {
    if (!Platform.isAndroid) return true;

    // Request Schedule Exact Alarm for Android 12+
    if (await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      if (status.isDenied) return false;
    }

    // Request Notification permission for Android 13+
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    return true;
  }

  static Future<bool> checkAndRequestSystemAlertWindow() async {
    if (!Platform.isAndroid) return true;
    
    if (await Permission.systemAlertWindow.isDenied) {
      final status = await Permission.systemAlertWindow.request();
      return status.isGranted;
    }
    return true;
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (Platform.isAndroid) {
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }
  }

  static Future<void> openAppInfo() async {
     await openAppSettings();
  }
}
