import 'package:get_it/get_it.dart';
import 'package:eco_check/presentation/blocs/auth/auth_bloc.dart';
import 'package:eco_check/presentation/blocs/checkin/checkin_bloc.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_bloc.dart';
import 'package:eco_check/presentation/blocs/gamification/gamification_bloc.dart';

/// Dependency Injection Container
final sl = GetIt.instance;

/// Initialize Dependencies
Future<void> initializeDependencies() async {
  // BLoCs
  sl.registerFactory(() => AuthBloc());
  sl.registerFactory(() => CheckinBloc());
  sl.registerFactory(() => ScheduleBloc());
  sl.registerFactory(() => GamificationBloc());

  // TODO: Register Repositories
  // sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // TODO: Register Data Sources
  // sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));

  // TODO: Register External Dependencies (Dio, SharedPreferences, etc.)
  // sl.registerLazySingleton(() => Dio());
}
