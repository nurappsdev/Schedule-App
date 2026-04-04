import 'dart:convert';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_device_apps/device_apps.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../../domain/entities/app_entity.dart';
import '../../domain/entities/schedule_entity.dart';
import '../../domain/entities/history_entity.dart';

// টপ-লেভেল ফাংশন যা ব্যাকগ্রাউন্ডে হিস্ট্রি সেভ করবে
@pragma('vm:entry-point')
Future<void> historyCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  print("🔔 [Background] History Callback Triggered for ID: $id");

  try {
    await Hive.initFlutter();
    const String boxName = 'schedules_box';
    const String historyBoxName = 'history_box';
    
    final box = await Hive.openBox(boxName);
    final historyBox = await Hive.openBox(historyBoxName);
    
    final schedules = box.values.map((e) => ScheduleEntity.fromJson(jsonDecode(e))).toList();
    final schedule = schedules.firstWhere(
      (s) => s.alarmId == id,
      orElse: () => throw "Schedule not found",
    );

    // Save to history
    final history = HistoryEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      app: schedule.app,
      executionTime: DateTime.now(),
      label: schedule.label,
    );
    await historyBox.add(jsonEncode(history.toJson()));

    // Delete the one-shot schedule from box after execution
    await box.delete(schedule.id);
    
    print("✅ [Background] History saved and schedule cleaned up.");
  } catch (e) {
    print("❌ [Background] History Error: $e");
  }
}

abstract class AppsLocalDataSource {
  Future<List<AppEntity>> getInstalledApps();
  Future<AppEntity> cloneApp(AppEntity app);
  Future<void> openApp(String packageName);
  Future<void> openClonedApk(String path);
  Future<List<ScheduleEntity>> getSchedules();
  Future<void> saveSchedule(ScheduleEntity schedule);
  Future<void> deleteSchedule(String id);
  Future<List<HistoryEntity>> getHistory();
  Future<void> clearHistory();
}

class AppsLocalDataSourceImpl implements AppsLocalDataSource {
  static const platform = MethodChannel("multi.parallel.channel");
  static const String _boxName = 'schedules_box';
  static const String _historyBoxName = 'history_box';

  Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<Box> _openHistoryBox() async {
    if (!Hive.isBoxOpen(_historyBoxName)) {
      return await Hive.openBox(_historyBoxName);
    }
    return Hive.box(_historyBoxName);
  }

  @override
  Future<List<AppEntity>> getInstalledApps() async {
    final List result = await platform.invokeMethod("getInstalledApps");
    List<AppEntity> apps = [];
    for (var app in result) {
      final deviceApp = await DeviceApps.getApp(app["packageName"], true);
      Uint8List? icon;
      if (deviceApp is ApplicationWithIcon) {
        icon = deviceApp.icon;
      }
      apps.add(AppEntity(
        name: app["appName"],
        packageName: app["packageName"],
        icon: icon,
      ));
    }
    return apps;
  }

  @override
  Future<AppEntity> cloneApp(AppEntity app) async {
    final deviceApp = await DeviceApps.getApp(app.packageName, true);
    if (deviceApp == null) throw "App not found";

    final apkPath = deviceApp.apkFilePath;
    final dir = await getExternalStorageDirectory();
    if (dir == null) throw "Could not access external storage";

    final newPath = '${dir.path}/${app.name}.apk';
    await File(apkPath).copy(newPath);

    return AppEntity(
      name: app.name,
      packageName: app.packageName,
      apkPath: newPath,
      icon: app.icon,
      isCloned: true,
    );
  }

  @override
  Future<void> openApp(String packageName) async {
    print("Directly launching app: $packageName");
    try {
      final result = await platform.invokeMethod("launchApp", {"packageName": packageName});
      print("Direct Launch Result: $result");
    } catch (e) {
      print("Error in direct launch: $e");
    }
  }

  @override
  Future<void> openClonedApk(String path) async {
    final intent = AndroidIntent(
      action: 'action_view',
      data: 'file://$path',
      type: 'application/vnd.android.package-archive',
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
  }

  @override
  Future<List<ScheduleEntity>> getSchedules() async {
    final box = await _openBox();
    final List<dynamic> rawSchedules = box.values.toList();
    return rawSchedules.map((e) => ScheduleEntity.fromJson(jsonDecode(e))).toList();
  }

  @override
  Future<void> saveSchedule(ScheduleEntity schedule) async {
    final box = await _openBox();
    await box.put(schedule.id, jsonEncode(schedule.toJson()));

    print("Setting native alarm for ${schedule.alarmId} at ${schedule.scheduledTime}");
    
    // ১. নেটিভ অ্যালার্ম সেট করা (অ্যাপ লঞ্চের জন্য - ১০০% গ্যারান্টি)
    try {
      await platform.invokeMethod("scheduleAlarm", {
        "packageName": schedule.app.packageName,
        "alarmId": schedule.alarmId,
        "timeMillis": schedule.scheduledTime.millisecondsSinceEpoch,
      });
      print("✅ Native alarm scheduled successfully");
    } catch (e) {
      print("❌ Failed to schedule native alarm: $e");
    }

    // ২. ডার্ট অ্যালার্ম সেট করা (শুধুমাত্র হিস্ট্রি সেভ করার জন্য)
    await AndroidAlarmManager.oneShotAt(
      schedule.scheduledTime,
      schedule.alarmId,
      historyCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );
  }

  @override
  Future<void> deleteSchedule(String id) async {
    final box = await _openBox();
    final raw = box.get(id);
    if (raw != null) {
      final schedule = ScheduleEntity.fromJson(jsonDecode(raw));
      // নেটিভ অ্যালার্ম ক্যানসেল করা
      try {
        await platform.invokeMethod("cancelAlarm", {"alarmId": schedule.alarmId});
      } catch (e) {
        print("Error cancelling native alarm: $e");
      }
      // ডার্ট অ্যালার্ম ক্যানসেল করা
      await AndroidAlarmManager.cancel(schedule.alarmId);
    }
    await box.delete(id);
  }

  @override
  Future<List<HistoryEntity>> getHistory() async {
    final box = await _openHistoryBox();
    final List<dynamic> rawHistory = box.values.toList();
    return rawHistory.map((e) => HistoryEntity.fromJson(jsonDecode(e))).toList();
  }

  @override
  Future<void> clearHistory() async {
    final box = await _openHistoryBox();
    await box.clear();
  }
}
