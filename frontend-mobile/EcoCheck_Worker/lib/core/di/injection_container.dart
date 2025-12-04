/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Worker - Dependency Injection Container
 */

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../services/socket_service.dart';
import '../../data/repositories/ecocheck_repository.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/route/route_bloc.dart';
import '../../presentation/blocs/collection/collection_bloc.dart';

/// Dependency Injection Container
final sl = GetIt.instance;

/// Initialize Dependencies
Future<void> initializeDependencies() async {
  // External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Network
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // Socket.IO Service
  sl.registerLazySingleton<SocketService>(() => SocketService());

  // Repository - Unified repository for all API calls
  sl.registerLazySingleton<EcoCheckRepository>(
    () => EcoCheckRepository(sl<ApiClient>()),
  );

  // BLoCs - Register as factories so each widget gets a new instance
  sl.registerFactory(
    () => AuthBloc(
      repository: sl<EcoCheckRepository>(),
      prefs: sl<SharedPreferences>(),
      socketService: sl<SocketService>(),
    ),
  );

  sl.registerFactory(() => RouteBloc(repository: sl<EcoCheckRepository>()));

  sl.registerFactory(
    () => CollectionBloc(repository: sl<EcoCheckRepository>()),
  );
}
