import 'package:get_it/get_it.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/repositories/sensor_repository_impl.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../../domain/usecases/get_device_heading.dart';
import '../../domain/usecases/get_device_tilt.dart';
import '../../domain/usecases/get_user_location.dart';
import '../../domain/usecases/get_ar_qibla_bearing.dart';
import '../../presentation/cubits/ar_cubit.dart';
import '../../presentation/cubits/tilt_cubit.dart';
import '../../services/ar_initialization_manager.dart';
import '../../services/qibla_initialization_manager.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // Repositories
  getIt.registerLazySingleton<LocationRepository>(() => LocationRepositoryImpl());
  getIt.registerLazySingleton<SensorRepository>(() => SensorRepositoryImpl());
  
  // Use Cases
  getIt.registerLazySingleton(() => GetUserLocation(getIt()));
  getIt.registerLazySingleton(() => GetDeviceHeading(getIt()));
  getIt.registerLazySingleton(() => GetDeviceTilt(getIt()));
  getIt.registerLazySingleton(() => GetARQiblaBearing());
  
  // Cubits
  getIt.registerFactory(() => ARCubit(
    getUserLocation: getIt(),
    getARQiblaBearing: getIt(),
    getDeviceHeading: getIt(),
  ));
  getIt.registerFactory(() => TiltCubit(getDeviceTilt: getIt()));
  
  // Configure AR Initialization Manager with dependencies
  ARInitializationManager.instance.configureDependencies(
    getUserLocation: getIt(),
    getARQiblaBearing: getIt(),
    getDeviceHeading: getIt(),
  );
  
  // Configure Qibla Initialization Manager with dependencies
  QiblaInitializationManager.instance.configureDependencies(
    getUserLocation: getIt(),
    getARQiblaBearing: getIt(),
  );
}
