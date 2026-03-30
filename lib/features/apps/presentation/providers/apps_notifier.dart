import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_entity.dart';
import '../../domain/entities/schedule_entity.dart';
import 'apps_provider.dart';

class AppsState {
  final List<AppEntity> installedApps;
  final List<AppEntity> clonedApps;
  final List<ScheduleEntity> schedules;
  final bool isLoading;

  AppsState({
    required this.installedApps,
    required this.clonedApps,
    required this.schedules,
    required this.isLoading,
  });

  factory AppsState.initial() => AppsState(
        installedApps: [],
        clonedApps: [],
        schedules: [],
        isLoading: false,
      );

  AppsState copyWith({
    List<AppEntity>? installedApps,
    List<AppEntity>? clonedApps,
    List<ScheduleEntity>? schedules,
    bool? isLoading,
  }) {
    return AppsState(
      installedApps: installedApps ?? this.installedApps,
      clonedApps: clonedApps ?? this.clonedApps,
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AppsNotifier extends Notifier<AppsState> {
  @override
  AppsState build() {
    // Schedule loadApps to run after this build cycle
    Future.microtask(() => loadAll());
    return AppsState.initial().copyWith(isLoading: true);
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(appsRepositoryProvider);
      final apps = await repository.getInstalledApps();
      final schedules = await repository.getSchedules();
      state = state.copyWith(
        installedApps: apps,
        schedules: schedules,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> saveSchedule(ScheduleEntity schedule) async {
    // Validate time is in future
    if (schedule.scheduledTime.isBefore(DateTime.now())) {
      throw "Scheduled time must be in the future";
    }

    // Check for conflicts (same hour and minute)
    final conflict = state.schedules.any((s) =>
        s.id != schedule.id &&
        s.scheduledTime.year == schedule.scheduledTime.year &&
        s.scheduledTime.month == schedule.scheduledTime.month &&
        s.scheduledTime.day == schedule.scheduledTime.day &&
        s.scheduledTime.hour == schedule.scheduledTime.hour &&
        s.scheduledTime.minute == schedule.scheduledTime.minute);

    if (conflict) {
      final existing = state.schedules.firstWhere((s) =>
          s.scheduledTime.year == schedule.scheduledTime.year &&
          s.scheduledTime.month == schedule.scheduledTime.month &&
          s.scheduledTime.day == schedule.scheduledTime.day &&
          s.scheduledTime.hour == schedule.scheduledTime.hour &&
          s.scheduledTime.minute == schedule.scheduledTime.minute);
      throw "Conflict: ${existing.app.name} is already scheduled at this time";
    }

    final repository = ref.read(appsRepositoryProvider);
    await repository.saveSchedule(schedule);
    
    final updatedSchedules = await repository.getSchedules();
    state = state.copyWith(schedules: updatedSchedules);
  }

  Future<void> deleteSchedule(String id) async {
    final repository = ref.read(appsRepositoryProvider);
    await repository.deleteSchedule(id);
    
    final updatedSchedules = await repository.getSchedules();
    state = state.copyWith(schedules: updatedSchedules);
  }

  Future<void> cloneApp(AppEntity app) async {
    try {
      final repository = ref.read(appsRepositoryProvider);
      final clonedApp = await repository.cloneApp(app);
      state = state.copyWith(
        clonedApps: [...state.clonedApps, clonedApp],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openApp(String packageName) async {
    final repository = ref.read(appsRepositoryProvider);
    await repository.openApp(packageName);
  }

  Future<void> openClonedApk(String path) async {
    final repository = ref.read(appsRepositoryProvider);
    await repository.openClonedApk(path);
  }
}

final appsNotifierProvider = NotifierProvider<AppsNotifier, AppsState>(() {
  return AppsNotifier();
});
