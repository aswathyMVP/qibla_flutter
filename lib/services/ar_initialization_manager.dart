import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/entities/location_data.dart';
import '../domain/usecases/get_user_location.dart';
import '../domain/usecases/get_ar_qibla_bearing.dart';
import '../domain/usecases/get_device_heading.dart';

/// Represents the current state of AR initialization
enum ARInitializationStatus {
  /// AR has not been initialized yet
  notInitialized,

  /// AR is currently initializing
  initializing,

  /// AR initialization completed successfully
  initialized,

  /// AR initialization failed
  failed,
}

/// Data class holding AR initialization state and results
class ARInitializationState {
  final ARInitializationStatus status;
  final LocationData? userLocation;
  final double? qiblaBearing;
  final double? deviceHeading;
  final String? errorMessage;
  final DateTime? initializedAt;

  const ARInitializationState({
    required this.status,
    this.userLocation,
    this.qiblaBearing,
    this.deviceHeading,
    this.errorMessage,
    this.initializedAt,
  });

  ARInitializationState copyWith({
    ARInitializationStatus? status,
    LocationData? userLocation,
    double? qiblaBearing,
    double? deviceHeading,
    String? errorMessage,
    DateTime? initializedAt,
  }) {
    return ARInitializationState(
      status: status ?? this.status,
      userLocation: userLocation ?? this.userLocation,
      qiblaBearing: qiblaBearing ?? this.qiblaBearing,
      deviceHeading: deviceHeading ?? this.deviceHeading,
      errorMessage: errorMessage ?? this.errorMessage,
      initializedAt: initializedAt ?? this.initializedAt,
    );
  }

  bool get isInitialized => status == ARInitializationStatus.initialized;
  bool get isInitializing => status == ARInitializationStatus.initializing;
  bool get hasFailed => status == ARInitializationStatus.failed;
  bool get canRetry => status == ARInitializationStatus.failed || 
                       status == ARInitializationStatus.notInitialized;
}

/// Singleton manager for AR initialization
/// 
/// This manager allows consuming projects to pre-initialize AR resources
/// during app startup, reducing loading time when the AR screen is opened.
/// 
/// Usage in consuming project:
/// ```dart
/// // In main() or splash screen
/// await ARInitializationManager.instance.initialize();
/// 
/// // Check status before navigation
/// if (ARInitializationManager.instance.state.isInitialized) {
///   Navigator.push(context, MaterialPageRoute(builder: (_) => ARQiblaPage()));
/// }
/// 
/// // Listen to initialization progress
/// ARInitializationManager.instance.stateStream.listen((state) {
///   print('AR Status: ${state.status}');
/// });
/// ```
class ARInitializationManager {
  static ARInitializationManager? _instance;
  
  /// Get the singleton instance
  static ARInitializationManager get instance {
    _instance ??= ARInitializationManager._internal();
    return _instance!;
  }

  /// Reset the singleton (useful for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance?._stateController.close();
    _instance = null;
  }

  ARInitializationManager._internal() {
    _stateController = StreamController<ARInitializationState>.broadcast();
    _state = const ARInitializationState(
      status: ARInitializationStatus.notInitialized,
    );
  }

  late StreamController<ARInitializationState> _stateController;
  late ARInitializationState _state;

  GetUserLocation? _getUserLocation;
  GetARQiblaBearing? _getARQiblaBearing;
  GetDeviceHeading? _getDeviceHeading;

  /// Current initialization state
  ARInitializationState get state => _state;

  /// Stream of initialization state changes
  Stream<ARInitializationState> get stateStream => _stateController.stream;

  /// Configure dependencies (called by package during DI setup)
  void configureDependencies({
    required GetUserLocation getUserLocation,
    required GetARQiblaBearing getARQiblaBearing,
    required GetDeviceHeading getDeviceHeading,
  }) {
    _getUserLocation = getUserLocation;
    _getARQiblaBearing = getARQiblaBearing;
    _getDeviceHeading = getDeviceHeading;
  }

  void _updateState(ARInitializationState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Initialize AR resources
  /// 
  /// This method can be called during app startup to pre-initialize AR.
  /// It handles:
  /// - Camera permission requests
  /// - Location permission requests
  /// - GPS location acquisition
  /// - Qibla bearing calculation
  /// - Device heading detection
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
      debugPrint('ARInitializationManager: Already initializing, waiting...');
      await stateStream.firstWhere((s) => !s.isInitializing);
      return _state.isInitialized;
    }

    // Return cached result if already initialized
    if (_state.isInitialized) {
      debugPrint('ARInitializationManager: Already initialized');
      return true;
    }

    _updateState(_state.copyWith(
      status: ARInitializationStatus.initializing,
      errorMessage: null,
    ));

    try {
      // Ensure dependencies are configured
      if (_getUserLocation == null || 
          _getARQiblaBearing == null || 
          _getDeviceHeading == null) {
        throw Exception(
          'ARInitializationManager dependencies not configured. '
          'Ensure configureDependencies() is called during package setup.'
        );
      }

      // Check and request camera permission
      debugPrint('ARInitializationManager: Checking camera permission...');
      final cameraStatus = await Permission.camera.status;
      
      if (!cameraStatus.isGranted) {
        debugPrint('ARInitializationManager: Requesting camera permission...');
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          throw Exception('Camera permission is required for AR');
        }
      }
      debugPrint('ARInitializationManager: Camera permission granted');

      double? qiblaBearing;
      double? deviceHeading;
      LocationData? userLocation;

      // Use existing Qibla bearing if provided
      if (existingQiblaBearing != null) {
        debugPrint('ARInitializationManager: Using existing Qibla bearing: $existingQiblaBearing°');
        qiblaBearing = existingQiblaBearing;
        deviceHeading = 0.0;
      } else {
        // Get location and calculate Qibla bearing
        try {
          debugPrint('ARInitializationManager: Checking location permission...');
          final locationStatus = await Permission.location.status;
          
          if (!locationStatus.isGranted) {
            debugPrint('ARInitializationManager: Requesting location permission...');
            final result = await Permission.location.request();
            if (!result.isGranted) {
              throw Exception('Location permission is required to calculate Qibla direction');
            }
          }
          debugPrint('ARInitializationManager: Location permission granted');
          
          debugPrint('ARInitializationManager: Getting user location (timeout: ${timeout.inSeconds}s)...');
          final locationStream = _getUserLocation!();
          userLocation = await locationStream.first.timeout(timeout);
          
          debugPrint('ARInitializationManager: Location acquired: ${userLocation.latitude}, ${userLocation.longitude}');
          
          // Calculate Qibla bearing
          qiblaBearing = _getARQiblaBearing!(userLocation);
          debugPrint('ARInitializationManager: Qibla bearing calculated: $qiblaBearing°');
          
          // Get device heading
          try {
            final headingStream = _getDeviceHeading!();
            final headingData = await headingStream.first.timeout(
              const Duration(seconds: 5),
            );
            deviceHeading = headingData.heading;
            debugPrint('ARInitializationManager: Device heading: $deviceHeading°');
          } catch (e) {
            debugPrint('ARInitializationManager: Could not get compass heading, using 0°');
            deviceHeading = 0.0;
          }
        } catch (e) {
          if (skipLocationIfFailed) {
            debugPrint('ARInitializationManager: Location failed but continuing with defaults: $e');
            qiblaBearing = 0.0;
            deviceHeading = 0.0;
          } else {
            rethrow;
          }
        }
      }

      // Success
      _updateState(ARInitializationState(
        status: ARInitializationStatus.initialized,
        userLocation: userLocation,
        qiblaBearing: qiblaBearing,
        deviceHeading: deviceHeading,
        initializedAt: DateTime.now(),
      ));

      debugPrint('ARInitializationManager: Initialization complete');
      return true;

    } catch (e) {
      debugPrint('ARInitializationManager: Initialization failed: $e');
      
      String errorMessage = _buildErrorMessage(e);
      
      _updateState(ARInitializationState(
        status: ARInitializationStatus.failed,
        errorMessage: errorMessage,
      ));

      return false;
    }
  }

  String _buildErrorMessage(dynamic error) {
    String errorMessage = 'Unable to initialize AR.\n\n';
    
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
      errorMessage += 'Required permission was denied.\n\n'
          'Please enable permissions in:\n'
          'Settings > [App Name] > Permissions';
    } else {
      errorMessage += 'Error: ${error.toString()}';
    }
    
    return errorMessage;
  }

  /// Reset initialization state (useful for retry scenarios)
  void reset() {
    debugPrint('ARInitializationManager: Resetting state');
    _updateState(const ARInitializationState(
      status: ARInitializationStatus.notInitialized,
    ));
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }
}
