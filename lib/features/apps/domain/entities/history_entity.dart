import 'app_entity.dart';

class HistoryEntity {
  final String id;
  final AppEntity app;
  final DateTime executionTime;
  final String label;

  const HistoryEntity({
    required this.id,
    required this.app,
    required this.executionTime,
    required this.label,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageName': app.packageName,
      'appName': app.name,
      'executionTime': executionTime.toIso8601String(),
      'label': label,
    };
  }

  factory HistoryEntity.fromJson(Map<String, dynamic> json) {
    return HistoryEntity(
      id: json['id'],
      app: AppEntity(
        name: json['appName'],
        packageName: json['packageName'],
      ),
      executionTime: DateTime.parse(json['executionTime']),
      label: json['label'],
    );
  }
}
