import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../cubits/ar_cubit.dart';

/// Enhanced AR View for Android - Same as iOS
/// The Kaaba stays fixed in the Qibla direction regardless of phone movement
class ARViewEnhancedAndroid extends StatefulWidget {
  final double qiblaBearing;
  final double deviceHeading;
  final bool showOverlay;
  final Color primaryColor;

  const ARViewEnhancedAndroid({
    super.key,
    required this.qiblaBearing,
    required this.deviceHeading,
    required this.showOverlay,
   required  this.primaryColor,
  });

  @override
  State<ARViewEnhancedAndroid> createState() => _ARViewEnhancedAndroidState();
}

class _ARViewEnhancedAndroidState extends State<ARViewEnhancedAndroid> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  
  // Real-time compass tracking
  StreamSubscription? _compassSubscription;
  double _currentHeading = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startCompassTracking();
    
    // Notify that AR is ready
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.read<ARCubit>().onPlaneDetected();
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
    _cameraController?.dispose();
    super.dispose();
  }

  void _startCompassTracking() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        setState(() {
          _currentHeading = event.heading!;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate angle difference for arrow direction
    double angleDiff = widget.qiblaBearing - _currentHeading;
    while (angleDiff > 180) {
      angleDiff -= 360;
    }
    while (angleDiff < -180) {
      angleDiff += 360;
    }

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
            child:  Center(
              child: CircularProgressIndicator(color:widget. primaryColor),
            ),
          ),

        // Left/Right arrow hints for navigation
        if (angleDiff < -5 || angleDiff > 5)
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 100,
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
                  color: widget. primaryColor,
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
        if (widget.showOverlay)
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: _buildNavigationOverlay(),
          ),

        // Kaaba image overlay - ALWAYS visible, locked to exact Qibla direction
        _buildKaabaPositionedOverlay(angleDiff, context),
      ],
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoChip(
              'You', '${_currentHeading.toStringAsFixed(0)}°', Colors.blue),
          _buildInfoChip('Qibla', '${widget.qiblaBearing.toStringAsFixed(0)}°',
              widget.primaryColor),
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

  // Build Kaaba positioned overlay based on Qibla direction
  Widget _buildKaabaPositionedOverlay(double angleDiff, BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate position based on angle difference
    const fovHorizontal = 70.0;
    final horizontalPixelsPerDegree = screenSize.width / fovHorizontal;
    
    // Calculate horizontal offset
    final horizontalOffset = angleDiff * horizontalPixelsPerDegree;
    final xPosition = (screenSize.width / 2) + horizontalOffset;
    
    return Positioned(
      left: xPosition - 60, // Center the Kaaba
      top: screenSize.height / 2 - 75, // Center vertically
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
}
