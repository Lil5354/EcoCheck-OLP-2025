import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eco_check/core/network/api_client.dart';
import 'package:eco_check/data/repositories/ecocheck_repository.dart';
import 'package:eco_check/data/services/sync_service.dart';
import 'package:eco_check/presentation/blocs/auth/auth_bloc.dart';
import 'package:eco_check/presentation/blocs/checkin/checkin_bloc.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_bloc.dart';
import 'package:eco_check/presentation/blocs/gamification/gamification_bloc.dart';
import 'package:eco_check/presentation/blocs/statistics/statistics_bloc.dart';

/// Dependency Injection Container
final sl = GetIt.instance;

/// Initialize Dependencies
Future<void> initializeDependencies() async {
  // External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Network
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // Repository
  sl.registerLazySingleton<EcoCheckRepository>(
    () => EcoCheckRepository(sl<ApiClient>()),
  );

  // Services
  sl.registerLazySingleton<SyncService>(
    () => SyncService(
      repository: sl<EcoCheckRepository>(),
      prefs: sl<SharedPreferences>(),
    ),
  );

  // BLoCs - Register as factories so each widget gets a new instance
  sl.registerFactory(
    () => AuthBloc(
      repository: sl<EcoCheckRepository>(),
      prefs: sl<SharedPreferences>(),
      syncService: sl<SyncService>(),
    ),
  );
  sl.registerFactory(() => CheckinBloc(repository: sl<EcoCheckRepository>()));
  sl.registerFactory(
    () => ScheduleBloc(
      repository: sl<EcoCheckRepository>(),
      prefs: sl<SharedPreferences>(),
    ),
  );
  sl.registerFactory(
    () => GamificationBloc(repository: sl<EcoCheckRepository>()),
  );
  sl.registerFactory(
    () => StatisticsBloc(repository: sl<EcoCheckRepository>()),
  );
}
