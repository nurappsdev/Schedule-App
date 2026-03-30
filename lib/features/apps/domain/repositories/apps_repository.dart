import '../entities/app_entity.dart';
import '../entities/schedule_entity.dart';

abstract class AppsRepository {
  Future<List<AppEntity>> getInstalledApps();
  Future<AppEntity> cloneApp(AppEntity app);
  Future<void> openApp(String packageName);
  Future<void> openClonedApk(String path);
  
  // Schedule methods
  Future<List<ScheduleEntity>> getSchedules();
  Future<void> saveSchedule(ScheduleEntity schedule);
  Future<void> deleteSchedule(String id);
}
