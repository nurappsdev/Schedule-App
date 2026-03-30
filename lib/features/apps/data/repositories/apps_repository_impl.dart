import '../../domain/entities/app_entity.dart';
import '../../domain/entities/schedule_entity.dart';
import '../../domain/repositories/apps_repository.dart';
import '../datasources/apps_local_datasource.dart';

class AppsRepositoryImpl implements AppsRepository {
  final AppsLocalDataSource localDataSource;

  AppsRepositoryImpl(this.localDataSource);

  @override
  Future<List<AppEntity>> getInstalledApps() => localDataSource.getInstalledApps();

  @override
  Future<AppEntity> cloneApp(AppEntity app) => localDataSource.cloneApp(app);

  @override
  Future<void> openApp(String packageName) => localDataSource.openApp(packageName);

  @override
  Future<void> openClonedApk(String path) => localDataSource.openClonedApk(path);

  @override
  Future<List<ScheduleEntity>> getSchedules() => localDataSource.getSchedules();

  @override
  Future<void> saveSchedule(ScheduleEntity schedule) => localDataSource.saveSchedule(schedule);

  @override
  Future<void> deleteSchedule(String id) => localDataSource.deleteSchedule(id);
}
