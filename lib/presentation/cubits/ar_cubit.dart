import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/ar_node_data.dart';
import '../../domain/entities/location_data.dart';
import '../../domain/usecases/get_user_location.dart';
import '../../domain/usecases/get_ar_qibla_bearing.dart';
import '../../domain/usecases/get_device_heading.dart';
import '../../services/ar_initialization_manager.dart';
import 'ar_state.dart';

class ARCubit extends Cubit<ARState> {
  final GetUserLocation getUserLocation;
  final GetARQiblaBearing getARQiblaBearing;
  final GetDeviceHeading getDeviceHeading;

  ARCubit({
    required this.getUserLocation,
    required this.getARQiblaBearing,
    required this.getDeviceHeading,
  }) : super(ARInitial());

  ARNodeData? _qiblaNode;
  LocationData? _userLocation;
  double? _qiblaBearing;
  double? _deviceHeading;

  Future<void> initializeAR({double? existingQiblaBearing}) async {
    // Check if AR is already pre-initialized by ARInitializationManager
    final initManager = ARInitializationManager.instance;
    
    if (initManager.state.isInitialized) {
      debugPrint('AR: Using pre-initialized state from ARInitializationManager');
      _userLocation = initManager.state.userLocation;
      _qiblaBearing = initManager.state.qiblaBearing;
      _deviceHeading = initManager.state.deviceHeading;
      
      emit(ARReady());
      return;
    }

    if (initManager.state.isInitializing) {
      debugPrint('AR: ARInitializationManager is initializing, waiting...');
      emit(ARLoading());
      
      // Wait for initialization to complete
      await initManager.stateStream.firstWhere((s) => !s.isInitializing);
      
      if (initManager.state.isInitialized) {
        _userLocation = initManager.state.userLocation;
        _qiblaBearing = initManager.state.qiblaBearing;
        _deviceHeading = initManager.state.deviceHeading;
        emit(ARReady());
      } else {
        emit(ARError(initManager.state.errorMessage ?? 'AR initialization failed'));
      }
      return;
    }

    // Fallback: Initialize AR directly if not pre-initialized
    debugPrint('AR: No pre-initialization found, initializing directly...');
    emit(ARLoading());

    try {
      // Check and request camera permission
      debugPrint('AR: Checking camera permission...');
      final cameraStatus = await Permission.camera.status;
      
      if (!cameraStatus.isGranted) {
        debugPrint('AR: Requesting camera permission...');
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          debugPrint('AR: Camera permission denied');
          emit(const ARError('Camera permission is required for AR'));
          return;
        }
      }
      debugPrint('AR: Camera permission granted');

      // Use existing Qibla bearing if provided (from compass page)
      if (existingQiblaBearing != null) {
        debugPrint('AR: Using existing Qibla bearing: $existingQiblaBearing°');
        _qiblaBearing = existingQiblaBearing;
        _deviceHeading = 0.0;
        
        debugPrint('AR: Initialization complete (using existing data), emitting ARReady');
        emit(ARReady());
        return;
      }

      // Otherwise, get location (fallback for direct AR access)
      debugPrint('AR: Checking location permission...');
      final locationStatus = await Permission.location.status;
      
      if (!locationStatus.isGranted) {
        debugPrint('AR: Requesting location permission...');
        final result = await Permission.location.request();
        if (!result.isGranted) {
          debugPrint('AR: Location permission denied');
          emit(const ARError('Location permission is required to calculate Qibla direction'));
          return;
        }
      }
      debugPrint('AR: Location permission granted');
      
      debugPrint('AR: Getting user location (this may take 30-60 seconds)...');
      try {
        final locationStream = getUserLocation();
        _userLocation = await locationStream.first.timeout(
          const Duration(seconds: 60), // Increased timeout to 60 seconds
        );
        
        debugPrint('AR: Location acquired: ${_userLocation?.latitude}, ${_userLocation?.longitude}');
        
        // Calculate Qibla bearing
        _qiblaBearing = getARQiblaBearing(_userLocation!);
        debugPrint('AR: Qibla bearing calculated: $_qiblaBearing°');
        
        // Get device heading
        try {
          final headingStream = getDeviceHeading();
          final headingData = await headingStream.first.timeout(
            const Duration(seconds: 5),
          );
          _deviceHeading = headingData.heading;
          debugPrint('AR: Device heading: $_deviceHeading°');
        } catch (e) {
          debugPrint('AR: Could not get compass heading, using 0°');
          _deviceHeading = 0.0;
        }
      } catch (e) {
        debugPrint('AR: Location error: $e');
        
        // Provide helpful error message
        String errorMessage = 'Unable to get GPS location.\n\n';
        if (e.toString().contains('TimeoutException')) {
          errorMessage += 'GPS signal acquisition timed out.\n\n'
              'What to do:\n'
              '1. Go outdoors (away from buildings)\n'
              '2. Wait 30-60 seconds for GPS lock\n'
              '3. Ensure Location Services are ON\n'
              '4. Check that app has location permission\n'
              '5. Try restarting the app\n\n'
              'GPS needs clear sky view to work.';
        } else if (e.toString().contains('Permission')) {
          errorMessage += 'Location permission was denied.\n\n'
              'Please enable location permission in:\n'
              'Settings > [App Name] > Location';
        } else {
          errorMessage += 'Error: ${e.toString()}';
        }
        
        emit(ARError(errorMessage));
        return;
      }

      debugPrint('AR: Initialization complete, emitting ARReady');
      emit(ARReady());
    } catch (e) {
      debugPrint('AR: Initialization failed: $e');
      emit(ARError('Failed to initialize AR: ${e.toString()}'));
    }
  }

  double? get qiblaBearing => _qiblaBearing;
  double? get deviceHeading => _deviceHeading;
  LocationData? get userLocation => _userLocation;

  void placeQiblaObject(Vector3 position, double qiblaDirection) {
    _qiblaNode = ARNodeData(
      id: 'qibla_kaaba',
      position: position,
      rotation: Vector3(0, qiblaDirection, 0),
      scale: Vector3(0.1, 0.1, 0.1),
      modelPath: 'assets/models/kaaba.glb',
      isPlaced: true,
    );
    emit(ARObjectPlaced(_qiblaNode!));
  }

  void updateObjectPosition(Vector3 newPosition) {
    if (_qiblaNode != null) {
      _qiblaNode = _qiblaNode!.copyWith(position: newPosition);
      emit(ARObjectUpdated(_qiblaNode!));
    }
  }

  void updateObjectRotation(Vector3 newRotation) {
    if (_qiblaNode != null) {
      _qiblaNode = _qiblaNode!.copyWith(rotation: newRotation);
      emit(ARObjectUpdated(_qiblaNode!));
    }
  }

  void updateObjectScale(Vector3 newScale) {
    if (_qiblaNode != null) {
      _qiblaNode = _qiblaNode!.copyWith(scale: newScale);
      emit(ARObjectUpdated(_qiblaNode!));
    }
  }

  void removeObject() {
    _qiblaNode = null;
    emit(ARObjectRemoved());
  }

  void onPlaneDetected() {
    emit(ARPlaneDetected());
  }

  void handleError(String message) {
    emit(ARError(message));
  }

  ARNodeData? get qiblaNode => _qiblaNode;
}
