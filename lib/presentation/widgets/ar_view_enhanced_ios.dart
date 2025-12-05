import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:flutter_compass/flutter_compass.dart';
import '../cubits/ar_cubit.dart';

/// Enhanced AR View for iOS with automatic Kaaba placement and navigation arrows
class ARViewEnhancedIOS extends StatefulWidget {
  final double qiblaBearing;
  final double deviceHeading;
  final bool showOverlay;
  const ARViewEnhancedIOS(
      {super.key,
      required this.qiblaBearing,
      required this.deviceHeading,
      required this.showOverlay});

  @override
  State<ARViewEnhancedIOS> createState() => _ARViewEnhancedIOSState();
}

class _ARViewEnhancedIOSState extends State<ARViewEnhancedIOS> {
  ARKitController? arkitController;
  String? _kaabaNodeName;
  String? _arrowNodeName;

  // Real-time compass tracking
  StreamSubscription? _compassSubscription;
  double _currentHeading = 0.0;

  // Distance to Kaaba (in meters, for AR placement)
  static const double kaabaDistance = 5.0; // 5 meters in front

  @override
  void initState() {
    super.initState();
    _startCompassTracking();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    arkitController?.dispose();
    super.dispose();
  }

  void _startCompassTracking() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        setState(() {
          _currentHeading = event.heading!;
        });
        _updateNavigationArrow();
      }
    });
  }

  void _onARKitViewCreated(ARKitController controller) {
    arkitController = controller;

    // Automatically place Kaaba after AR session starts
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _placeKaabaAutomatically();
        context.read<ARCubit>().onPlaneDetected();
      }
    });
  }

  void _placeKaabaAutomatically() {
    if (arkitController == null) return;

    // Calculate Kaaba position relative to user
    // Qibla bearing is the direction to Kaaba from user's location
    final qiblaRadians = widget.qiblaBearing * (math.pi / 180);

    // Place Kaaba at specified distance in Qibla direction
    // X: East-West (positive = East)
    // Y: Up-Down (0 = ground level)
    // Z: North-South (negative = North, positive = South)
    final x = kaabaDistance * math.sin(qiblaRadians);
    final z = -kaabaDistance * math.cos(qiblaRadians);
    final y = -0.5; // Slightly below eye level

    _placeKaaba(vector.Vector3(x, y, z), qiblaRadians);
    _placeNavigationArrow(vector.Vector3(x, y + 0.3, z)); // Arrow above Kaaba
  }

  void _placeKaaba(vector.Vector3 position, double rotation) {
    if (arkitController == null) return;

    // Remove previous Kaaba if exists
    if (_kaabaNodeName != null) {
      arkitController!.remove(_kaabaNodeName!);
    }

    ARKitNode node;

    try {
      // Try to load USDZ model (iOS format)
      node = ARKitReferenceNode(
        url: 'assets/models/kaaba.usdz',
        position: position,
        scale: vector.Vector3(0.01, 0.01, 0.01),
      );
      node.eulerAngles = vector.Vector3(0, rotation, 0);
    } catch (e) {
      // Fallback: Create a simple Kaaba representation
      node = _createSimpleKaaba(position, rotation);
    }

    _kaabaNodeName = 'kaaba_${DateTime.now().millisecondsSinceEpoch}';
    arkitController!.add(node, parentNodeName: null);

    context.read<ARCubit>().placeQiblaObject(
          position,
          widget.qiblaBearing,
        );
  }

  ARKitNode _createSimpleKaaba(vector.Vector3 position, double rotation) {
    // Create a simple black cube to represent Kaaba
    return ARKitNode(
      geometry: ARKitBox(
        width: 0.3,
        height: 0.4,
        length: 0.3,
        materials: [
          ARKitMaterial(
            diffuse: ARKitMaterialProperty.color(Colors.black),
            metalness: ARKitMaterialProperty.value(0.2),
            roughness: ARKitMaterialProperty.value(0.8),
          ),
        ],
      ),
      position: position,
      rotation: vector.Vector4(0, 1, 0, rotation),
    );
  }

  void _placeNavigationArrow(vector.Vector3 position) {
    if (arkitController == null) return;

    // Remove previous arrow if exists
    if (_arrowNodeName != null) {
      arkitController!.remove(_arrowNodeName!);
    }

    // Create a cone pointing down to Kaaba
    final arrowNode = ARKitNode(
      geometry: ARKitCone(
        topRadius: 0.0,
        bottomRadius: 0.1,
        height: 0.2,
        materials: [
          ARKitMaterial(
            diffuse: ARKitMaterialProperty.color(Colors.green),
            emission: ARKitMaterialProperty.color(
                Colors.green.withValues(alpha: 0.5)),
          ),
        ],
      ),
      position: position,
      rotation: vector.Vector4(1, 0, 0, math.pi), // Point downward
    );

    _arrowNodeName = 'arrow_${DateTime.now().millisecondsSinceEpoch}';
    arkitController!.add(arrowNode, parentNodeName: null);
  }

  void _updateNavigationArrow() {
    // Update arrow visibility/color based on alignment
    // This could be enhanced to animate or change color
  }

  @override
  Widget build(BuildContext context) {
    // Calculate angle difference for arrow direction
    double angleDiff = widget.qiblaBearing - _currentHeading;
    while (angleDiff > 180) angleDiff -= 360;
    while (angleDiff < -180) angleDiff += 360;



    return Stack(
      children: [
        // AR View
        ARKitSceneView(
          onARKitViewCreated: _onARKitViewCreated,
          enableTapRecognizer: false, // Disable tap, auto-place instead
          planeDetection: ARPlaneDetection.horizontal,
          showFeaturePoints: false,
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
              Colors.green),
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
