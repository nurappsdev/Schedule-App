import 'dart:convert';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';
import 'package:new_device_apps/device_apps.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../../domain/entities/app_entity.dart';
import '../../domain/entities/schedule_entity.dart';

abstract class AppsLocalDataSource {
  Future<List<AppEntity>> getInstalledApps();
  Future<AppEntity> cloneApp(AppEntity app);
  Future<void> openApp(String packageName);
  Future<void> openClonedApk(String path);
  
  // Schedule methods
  Future<List<ScheduleEntity>> getSchedules();
  Future<void> saveSchedule(ScheduleEntity schedule);
  Future<void> deleteSchedule(String id);
}

class AppsLocalDataSourceImpl implements AppsLocalDataSource {
  static const platform = MethodChannel("multi.parallel.channel");
  static const String _boxName = 'schedules_box';

  Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
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
    bool isOpened = await DeviceApps.openApp(packageName);
    if (!isOpened) throw "Failed to open app";
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

    // Schedule the alarm
    final int alarmId = schedule.id.hashCode.abs();
    await AndroidAlarmManager.oneShotAt(
      schedule.scheduledTime,
      alarmId,
      callback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      params: {'packageName': schedule.app.packageName},
    );
  }

  @override
  Future<void> deleteSchedule(String id) async {
    final box = await _openBox();
    await box.delete(id);

    // Cancel the alarm
    final int alarmId = id.hashCode.abs();
    await AndroidAlarmManager.cancel(alarmId);
  }

  @pragma('vm:entry-point')
  static Future<void> callback(int id, Map<String, dynamic> params) async {
    final String? packageName = params['packageName'];
    if (packageName != null) {
      await DeviceApps.openApp(packageName);
    }
  }
}
