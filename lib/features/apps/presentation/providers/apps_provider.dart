import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/apps_local_datasource.dart';
import '../../data/repositories/apps_repository_impl.dart';
import '../../domain/repositories/apps_repository.dart';

final appsLocalDataSourceProvider = Provider<AppsLocalDataSource>((ref) {
  return AppsLocalDataSourceImpl();
});

final appsRepositoryProvider = Provider<AppsRepository>((ref) {
  final localDataSource = ref.watch(appsLocalDataSourceProvider);
  return AppsRepositoryImpl(localDataSource);
});
