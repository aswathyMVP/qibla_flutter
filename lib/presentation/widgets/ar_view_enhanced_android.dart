import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../cubits/ar_cubit.dart';

/// Enhanced AR View for Android with world-anchored Kaaba
/// The Kaaba stays fixed in the Qibla direction regardless of phone movement
class ARViewEnhancedAndroid extends StatefulWidget {
  final double qiblaBearing;
  final double deviceHeading;
  final bool showOverlay;

  const ARViewEnhancedAndroid({
    super.key,
    required this.qiblaBearing,
    required this.deviceHeading,
    required this.showOverlay,
  });

  @override
  State<ARViewEnhancedAndroid> createState() => _ARViewEnhancedAndroidState();
}

class _ARViewEnhancedAndroidState extends State<ARViewEnhancedAndroid> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  
  // Real-time sensor tracking
  StreamSubscription? _compassSubscription;
  StreamSubscription? _accelSubscription;
  
  double _currentHeading = 0.0;
  double _pitch = 0.0; // Up/down tilt
  
  // Smoothed position to reduce vibration
  Offset _smoothedKaabaPosition = Offset.zero;
  static const double _smoothingFactor = 0.1; // Lower = smoother (0.1 = very smooth)
  
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startSensorTracking();
    
    // Notify that AR is ready
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.read<ARCubit>().onPlaneDetected();
        context.read<ARCubit>().placeQiblaObject(
          vector.Vector3(0, 0, -5),
          widget.qiblaBearing,
        );
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _accelSubscription?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  void _startSensorTracking() {
    // Compass for heading (with smoothing)
    double _smoothedHeading = 0.0;
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        // Smooth compass readings to reduce jitter
        _smoothedHeading = _smoothedHeading + (event.heading! - _smoothedHeading) * 0.2;
        setState(() {
          _currentHeading = _smoothedHeading;
        });
      }
    });
    
    // Accelerometer for pitch (device orientation) with smoothing
    double smoothedPitch = 0.0;
    _accelSubscription = accelerometerEventStream().listen((event) {
      if (!mounted) return;
      
      // Calculate pitch (up/down tilt)
      final pitch = math.atan2(-event.x, math.sqrt(event.y * event.y + event.z * event.z));
      
      // Smooth pitch to reduce jitter
      smoothedPitch = smoothedPitch + (pitch * 180 / math.pi - smoothedPitch) * 0.2;
      
      setState(() {
        _pitch = smoothedPitch;
      });
    });
  }

  // Calculate where the Kaaba should appear on screen based on device orientation
  // Kaaba is ALWAYS visible and locked to exact Qibla direction
  Offset _calculateKaabaScreenPosition(Size screenSize) {
    // Calculate angle difference between current heading and Qibla
    double angleDiff = widget.qiblaBearing - _currentHeading;
    
    // Normalize to -180 to 180
    while (angleDiff > 180) angleDiff -= 360;
    while (angleDiff < -180) angleDiff += 360;
    
    // Calculate horizontal position
    // Assuming 60 degree horizontal FOV
    const fovHorizontal = 60.0;
    final horizontalRatio = angleDiff / (fovHorizontal / 2);
    final horizontalOffset = horizontalRatio * (screenSize.width / 2);
    final x = (screenSize.width / 2) + horizontalOffset;
    
    // Calculate vertical position based on pitch
    // Assuming 45 degree vertical FOV
    const fovVertical = 45.0;
    final verticalRatio = _pitch / (fovVertical / 2);
    final verticalOffset = verticalRatio * (screenSize.height / 2);
    final y = (screenSize.height / 2) - verticalOffset;
    
    final newPosition = Offset(x, y);
    
    // Initialize smoothed position on first frame
    if (_smoothedKaabaPosition == Offset.zero) {
      _smoothedKaabaPosition = newPosition;
      return _smoothedKaabaPosition;
    }
    
    // Calculate distance to new position
    final distance = (newPosition - _smoothedKaabaPosition).distance;
    
    // Only update if movement is significant (reduces micro-jitter)
    if (distance > 2.0) {
      // Apply smoothing to reduce vibration
      _smoothedKaabaPosition = Offset(
        _smoothedKaabaPosition.dx + (newPosition.dx - _smoothedKaabaPosition.dx) * _smoothingFactor,
        _smoothedKaabaPosition.dy + (newPosition.dy - _smoothedKaabaPosition.dy) * _smoothingFactor,
      );
    }
    
    return _smoothedKaabaPosition;
  }

  double get _angleDifference {
    double diff = (_currentHeading - widget.qiblaBearing).abs();
    return diff > 180 ? 360 - diff : diff;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final kaabaPosition = _calculateKaabaScreenPosition(screenSize);
    
    // Calculate angle difference for arrow direction
    double angleDiff = widget.qiblaBearing - _currentHeading;
    while (angleDiff > 180) angleDiff -= 360;
    while (angleDiff < -180) angleDiff += 360;
    


    return Stack(
      children: [
        // Camera View
        if (_isCameraInitialized && _cameraController != null)
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          ),
        
        // Kaaba - ALWAYS visible, locked to exact Qibla direction
        Positioned(
          left: kaabaPosition.dx - 50, // Center the 100px wide Kaaba
          top: kaabaPosition.dy - 60,  // Center the 120px tall Kaaba
          child: _buildKaabaOverlay(),
        ),
        
        // Left/Right arrow hints for navigation
        if (angleDiff < -5 || angleDiff > 5)
          Positioned(
            top: screenSize.height / 2 - 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  angleDiff < -5 ? 'Move Left' : 'Move Right',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Icon(
                  angleDiff < -5 
                      ? Icons.arrow_circle_left 
                      : Icons.arrow_circle_right,
                  color: Colors.green,
                  size: 100,
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ],
            ),
          ),
        
        // Navigation overlay
        if(widget.showOverlay)
        Positioned(
          top: 120,
          left: 0,
          right: 0,
          child: _buildNavigationOverlay(),
        ),
      ],
    );
  }

  Widget _buildKaabaOverlay() {
    // Scale based on distance (simulated)
    final scale = 1.0 - (_angleDifference / 180) * 0.3;
    
    return Transform.scale(
      scale: scale.clamp(0.7, 1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // White arrow pointing down
          const Icon(
            Icons.arrow_downward,
            color: Colors.white,
            size: 48,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 10,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Kaaba image (transparent, no border/shadow)
          Opacity(
            opacity: 0.8, // Semi-transparent
            child: Image.asset(
              'assets/images/qibla.png',
              package: 'qibla_ar_finder',
              width: 120,
              height: 150,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildNavigationOverlay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Compass info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoChip('You', '${_currentHeading.toStringAsFixed(0)}°', Colors.blue),
              _buildInfoChip('Qibla', '${widget.qiblaBearing.toStringAsFixed(0)}°', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
