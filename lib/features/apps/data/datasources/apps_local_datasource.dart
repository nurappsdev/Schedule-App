import 'dart:convert';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';
import 'package:new_device_apps/device_apps.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String _schedulesKey = 'app_schedules';

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
    final prefs = await SharedPreferences.getInstance();
    final String? schedulesJson = prefs.getString(_schedulesKey);
    if (schedulesJson == null) return [];

    final List<dynamic> decoded = jsonDecode(schedulesJson);
    return decoded.map((e) => ScheduleEntity.fromJson(e)).toList();
  }

  @override
  Future<void> saveSchedule(ScheduleEntity schedule) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ScheduleEntity> schedules = await getSchedules();
    
    // Check if updating or adding
    final int index = schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      schedules[index] = schedule;
    } else {
      schedules.add(schedule);
    }

    await prefs.setString(_schedulesKey, jsonEncode(schedules.map((e) => e.toJson()).toList()));
  }

  @override
  Future<void> deleteSchedule(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ScheduleEntity> schedules = await getSchedules();
    schedules.removeWhere((s) => s.id == id);
    await prefs.setString(_schedulesKey, jsonEncode(schedules.map((e) => e.toJson()).toList()));
  }
}
