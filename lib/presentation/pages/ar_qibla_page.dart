import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/ar_cubit.dart';
import '../cubits/ar_state.dart';
import '../cubits/qibla_cubit.dart';
import '../cubits/qibla_state.dart';
import '../widgets/ar_view_enhanced_android.dart';
import '../widgets/ar_view_enhanced_ios.dart';

class ARQiblaPage extends StatefulWidget {
  const ARQiblaPage({super.key});

  @override
  State<ARQiblaPage> createState() => _ARQiblaPageState();
}

class _ARQiblaPageState extends State<ARQiblaPage> {
  double? _qiblaBearing;
  double? _deviceHeading;

  @override
  void initState() {
    super.initState();
    _initializeAR();
  }

  Future<void> _initializeAR() async {
    // Try to get Qibla bearing from QiblaCubit (if available from compass page)
    double? existingQiblaBearing;
    try {
      final qiblaState = context.read<QiblaCubit>().state;
      if (qiblaState is QiblaUpdated) {
        existingQiblaBearing = qiblaState.qiblaData.qiblaDirection;
        debugPrint('AR: Got Qibla bearing from compass: $existingQiblaBearing°');
      }
    } catch (e) {
      debugPrint('AR: Could not get Qibla from compass cubit: $e');
    }
    
    await context.read<ARCubit>().initializeAR(existingQiblaBearing: existingQiblaBearing);
    _updateBearingInfo();
  }
 
  void _updateBearingInfo() {
    final arCubit = context.read<ARCubit>();
    setState(() {
      _qiblaBearing = arCubit.qiblaBearing;
      _deviceHeading = arCubit.deviceHeading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<ARCubit, ARState>(
        listener: (context, state) {
          if (state is ARReady) {
            // Update bearing info when AR is ready
            _updateBearingInfo();
          } else if (state is ARError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 5),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    _initializeAR();
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Enhanced AR View based on platform
              if (state is ARReady || state is ARPlaneDetected || state is ARObjectPlaced || state is ARObjectUpdated)
                Platform.isAndroid
                    ? ARViewEnhancedAndroid(
                        qiblaBearing: _qiblaBearing ?? 0,
                        deviceHeading: _deviceHeading ?? 0,
                      )
                    : ARViewEnhancedIOS(
                        qiblaBearing: _qiblaBearing ?? 0,
                        deviceHeading: _deviceHeading ?? 0,
                      ),

              // Loading indicator
              if (state is ARLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),

              // Error state
              if (state is ARError)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => _initializeAR(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Top bar with title
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'AR Qibla Direction',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Instructions overlay - Kaaba is automatically placed
              if (state is ARReady || state is ARPlaneDetected || state is ARObjectPlaced)
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.explore, color: Colors.green, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Kaaba placed automatically in Qibla direction',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Rotate your device to face the Kaaba\nFollow the navigation arrows',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // Qibla bearing indicator
              if (_qiblaBearing != null)
                Positioned(
                  top: 100,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.explore, color: Colors.white, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          _qiblaBearing == 0.0 ? 'Default' : 'Qibla',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _qiblaBearing == 0.0 ? 'North' : '${_qiblaBearing!.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Device heading indicator
              if (_deviceHeading != null)
                Positioned(
                  top: 100,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.navigation, color: Colors.white, size: 24),
                        const SizedBox(height: 4),
                        const Text(
                          'Heading',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '${_deviceHeading!.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
