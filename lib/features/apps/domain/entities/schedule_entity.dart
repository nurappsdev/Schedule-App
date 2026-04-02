import 'app_entity.dart';

class ScheduleEntity {
  final String id;
  final int alarmId;
  final AppEntity app;
  final String label;
  final DateTime scheduledTime;

  const ScheduleEntity({
    required this.id,
    required this.alarmId,
    required this.app,
    required this.label,
    required this.scheduledTime,
  });

  ScheduleEntity copyWith({
    String? id,
    int? alarmId,
    AppEntity? app,
    String? label,
    DateTime? scheduledTime,
  }) {
    return ScheduleEntity(
      id: id ?? this.id,
      alarmId: alarmId ?? this.alarmId,
      app: app ?? this.app,
      label: label ?? this.label,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alarmId': alarmId,
      'packageName': app.packageName,
      'appName': app.name,
      'label': label,
      'scheduledTime': scheduledTime.toIso8601String(),
    };
  }

  factory ScheduleEntity.fromJson(Map<String, dynamic> json) {
    return ScheduleEntity(
      id: json['id'],
      alarmId: json['alarmId'] ?? json['id'].hashCode.abs(),
      app: AppEntity(
        name: json['appName'],
        packageName: json['packageName'],
      ),
      label: json['label'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
    );
  }
}
