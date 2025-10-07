import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/network_info.dart';
import 'core/utils/search_history_storage.dart';
import 'features/catalog/data/datasources/product_local_datasource.dart';
import 'features/catalog/data/datasources/product_remote_datasource.dart';
import 'features/catalog/data/repositories/product_repository_impl.dart';
import 'features/catalog/domain/repositories/product_repository.dart';
import 'features/catalog/presentation/blocs/catalog_bloc.dart';
import 'features/product_detail/presentation/blocs/product_detail_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Catalog
  sl.registerFactory(() => CatalogBloc(repository: sl()));
  sl.registerFactory(() => ProductDetailBloc(repository: sl()));

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(sl()),
  );

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => SearchHistoryStorage(sl()));

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => Connectivity());
}
