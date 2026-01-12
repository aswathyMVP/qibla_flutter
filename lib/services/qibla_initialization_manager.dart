import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/entities/location_data.dart';
import '../domain/usecases/get_user_location.dart';
import '../domain/usecases/get_ar_qibla_bearing.dart';
import '../services/qiblah_service.dart';

/// Represents the current state of Qibla initialization
enum QiblaInitializationStatus {
  /// Qibla has not been initialized yet
  notInitialized,

  /// Qibla is currently initializing
  initializing,

  /// Qibla initialization completed successfully
  initialized,

  /// Qibla initialization failed
  failed,
}

/// Data class holding Qibla initialization state and results
class QiblaInitializationState {
  final QiblaInitializationStatus status;
  final LocationData? userLocation;
  final double? qiblaBearing;
  final LocationStatus? locationStatus;
  final String? errorMessage;
  final DateTime? initializedAt;

  const QiblaInitializationState({
    required this.status,
    this.userLocation,
    this.qiblaBearing,
    this.locationStatus,
    this.errorMessage,
    this.initializedAt,
  });

  QiblaInitializationState copyWith({
    QiblaInitializationStatus? status,
    LocationData? userLocation,
    double? qiblaBearing,
    LocationStatus? locationStatus,
    String? errorMessage,
    DateTime? initializedAt,
  }) {
    return QiblaInitializationState(
      status: status ?? this.status,
      userLocation: userLocation ?? this.userLocation,
      qiblaBearing: qiblaBearing ?? this.qiblaBearing,
      locationStatus: locationStatus ?? this.locationStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      initializedAt: initializedAt ?? this.initializedAt,
    );
  }

  bool get isInitialized => status == QiblaInitializationStatus.initialized;
  bool get isInitializing => status == QiblaInitializationStatus.initializing;
  bool get hasFailed => status == QiblaInitializationStatus.failed;
  bool get canRetry => status == QiblaInitializationStatus.failed || 
                       status == QiblaInitializationStatus.notInitialized;
  bool get hasLocationPermission => locationStatus?.enabled == true && 
    (locationStatus?.status == LocationPermission.always || 
     locationStatus?.status == LocationPermission.whileInUse);
}

/// Singleton manager for Qibla initialization
/// 
/// This manager allows consuming projects to pre-initialize Qibla resources
/// during app startup, reducing loading time when the Qibla screen is opened.
/// 
/// Usage in consuming project:
/// ```dart
/// // In main() or splash screen
/// await QiblaInitializationManager.instance.initialize();
/// 
/// // Check status before navigation
/// if (QiblaInitializationManager.instance.state.isInitialized) {
///   Navigator.push(context, MaterialPageRoute(builder: (_) => QiblaScreen()));
/// }
/// 
/// // Listen to initialization progress
/// QiblaInitializationManager.instance.stateStream.listen((state) {
///   print('Qibla Status: ${state.status}');
/// });
/// ```
class QiblaInitializationManager {
  static QiblaInitializationManager? _instance;
  
  /// Get the singleton instance
  static QiblaInitializationManager get instance {
    _instance ??= QiblaInitializationManager._internal();
    return _instance!;
  }

  /// Reset the singleton (useful for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance?._stateController.close();
    _instance = null;
  }

  QiblaInitializationManager._internal() {
    _stateController = StreamController<QiblaInitializationState>.broadcast();
    _state = const QiblaInitializationState(
      status: QiblaInitializationStatus.notInitialized,
    );
  }

  late StreamController<QiblaInitializationState> _stateController;
  late QiblaInitializationState _state;

  GetUserLocation? _getUserLocation;
  GetARQiblaBearing? _getARQiblaBearing;

  /// Current initialization state
  QiblaInitializationState get state => _state;

  /// Stream of initialization state changes
  Stream<QiblaInitializationState> get stateStream => _stateController.stream;

  /// Configure dependencies (called by package during DI setup)
  void configureDependencies({
    required GetUserLocation getUserLocation,
    required GetARQiblaBearing getARQiblaBearing,
  }) {
    _getUserLocation = getUserLocation;
    _getARQiblaBearing = getARQiblaBearing;
  }

  void _updateState(QiblaInitializationState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Initialize Qibla resources
  /// 
  /// This method can be called during app startup to pre-initialize Qibla.
  /// It handles:
  /// - Location permission requests
  /// - GPS location acquisition
  /// - Qibla bearing calculation
  /// - Location status checking
  /// 
  /// Parameters:
  /// - [existingQiblaBearing]: Optional pre-calculated Qibla bearing
  /// - [timeout]: Maximum time to wait for GPS (default: 60 seconds)
  /// - [skipLocationIfFailed]: If true, continues with default bearing on location failure
  /// 
  /// Returns: true if initialization succeeded, false otherwise
  Future<bool> initialize({
    double? existingQiblaBearing,
    Duration timeout = const Duration(seconds: 60),
    bool skipLocationIfFailed = false,
  }) async {
    // Prevent concurrent initialization
    if (_state.isInitializing) {
      debugPrint('QiblaInitializationManager: Already initializing, waiting...');
      await stateStream.firstWhere((s) => !s.isInitializing);
      return _state.isInitialized;
    }

    // Return cached result if already initialized
    if (_state.isInitialized) {
      debugPrint('QiblaInitializationManager: Already initialized');
      return true;
    }

    _updateState(_state.copyWith(
      status: QiblaInitializationStatus.initializing,
      errorMessage: null,
    ));

    try {
      // Ensure dependencies are configured
      if (_getUserLocation == null || _getARQiblaBearing == null) {
        throw Exception(
          'QiblaInitializationManager dependencies not configured. '
          'Ensure configureDependencies() is called during package setup.'
        );
      }

      double? qiblaBearing;
      LocationData? userLocation;
      LocationStatus? locationStatus;

      // Use existing Qibla bearing if provided
      if (existingQiblaBearing != null) {
        debugPrint('QiblaInitializationManager: Using existing Qibla bearing: $existingQiblaBearing°');
        qiblaBearing = existingQiblaBearing;
        
        // Still check location status for UI purposes
        try {
          locationStatus = await QiblahService.checkLocationStatus();
        } catch (e) {
          debugPrint('QiblaInitializationManager: Could not get location status: $e');
        }
      } else {
        // Get location status first
        try {
          debugPrint('QiblaInitializationManager: Checking location status...');
          locationStatus = await QiblahService.checkLocationStatus();
          
          if (!locationStatus.enabled) {
            throw Exception('Location services are disabled. Please enable location services.');
          }
          
          if (locationStatus.status == LocationPermission.denied) {
            debugPrint('QiblaInitializationManager: Requesting location permission...');
            await QiblahService.requestPermissions();
            locationStatus = await QiblahService.checkLocationStatus();
          }
          
          if (locationStatus.status == LocationPermission.denied || 
              locationStatus.status == LocationPermission.deniedForever) {
            throw Exception('Location permission is required to calculate Qibla direction');
          }
          
          debugPrint('QiblaInitializationManager: Location permission granted');
          
          // Get GPS location
          debugPrint('QiblaInitializationManager: Getting user location (timeout: ${timeout.inSeconds}s)...');
          final locationStream = _getUserLocation!();
          userLocation = await locationStream.first.timeout(timeout);
          
          debugPrint('QiblaInitializationManager: Location acquired: ${userLocation.latitude}, ${userLocation.longitude}');
          
          // Calculate Qibla bearing
          qiblaBearing = _getARQiblaBearing!(userLocation);
          debugPrint('QiblaInitializationManager: Qibla bearing calculated: $qiblaBearing°');
          
        } catch (e) {
          if (skipLocationIfFailed) {
            debugPrint('QiblaInitializationManager: Location failed but continuing with defaults: $e');
            qiblaBearing = 0.0;
            // Try to get location status anyway
            try {
              locationStatus = await QiblahService.checkLocationStatus();
            } catch (_) {
              // Ignore location status errors if we're skipping location
            }
          } else {
            rethrow;
          }
        }
      }

      // Success
      _updateState(QiblaInitializationState(
        status: QiblaInitializationStatus.initialized,
        userLocation: userLocation,
        qiblaBearing: qiblaBearing,
        locationStatus: locationStatus,
        initializedAt: DateTime.now(),
      ));

      debugPrint('QiblaInitializationManager: Initialization complete');
      return true;

    } catch (e) {
      debugPrint('QiblaInitializationManager: Initialization failed: $e');
      
      String errorMessage = _buildErrorMessage(e);
      
      _updateState(QiblaInitializationState(
        status: QiblaInitializationStatus.failed,
        errorMessage: errorMessage,
      ));

      return false;
    }
  }

  String _buildErrorMessage(dynamic error) {
    String errorMessage = 'Unable to initialize Qibla finder.\n\n';
    
    if (error.toString().contains('TimeoutException')) {
      errorMessage += 'GPS signal acquisition timed out.\n\n'
          'What to do:\n'
          '1. Go outdoors (away from buildings)\n'
          '2. Wait 30-60 seconds for GPS lock\n'
          '3. Ensure Location Services are ON\n'
          '4. Check that app has location permission\n'
          '5. Try restarting the app\n\n'
          'GPS needs clear sky view to work.';
    } else if (error.toString().contains('Permission') || 
               error.toString().contains('permission')) {
      errorMessage += 'Location permission was denied.\n\n'
          'Please enable location permission in:\n'
          'Settings > [App Name] > Location';
    } else if (error.toString().contains('Location services')) {
      errorMessage += 'Location services are disabled.\n\n'
          'Please enable location services in:\n'
          'Settings > Location Services';
    } else {
      errorMessage += 'Error: ${error.toString()}';
    }
    
    return errorMessage;
  }

  /// Reset initialization state (useful for retry scenarios)
  void reset() {
    debugPrint('QiblaInitializationManager: Resetting state');
    _updateState(const QiblaInitializationState(
      status: QiblaInitializationStatus.notInitialized,
    ));
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }
}