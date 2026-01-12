import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qibla_ar_finder/qibla_ar_finder.dart';

/// Fixed Qibla Screen demonstrating proper LocationStatus usage
/// 
/// This example shows how to correctly use QiblahService.checkLocationStatus()
/// without the infinite loading issue.
class FixedQiblaScreen extends StatefulWidget {
  const FixedQiblaScreen({super.key});

  @override
  State<FixedQiblaScreen> createState() => _FixedQiblaScreenState();
}

class _FixedQiblaScreenState extends State<FixedQiblaScreen> {
  final _locationStreamController = StreamController<LocationStatus>.broadcast();
  
  // Use the stream directly from the controller
  Stream<LocationStatus> get locationStream => _locationStreamController.stream;

  @override
  void initState() {
    super.initState();
    // Call the async method properly
    _initializeLocationStatus();
  }

  @override
  void dispose() {
    _locationStreamController.close();
    QiblahService().dispose();
    super.dispose();
  }

  // Separate initialization method
  Future<void> _initializeLocationStatus() async {
    await _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    try {
      final locationStatus = await QiblahService.checkLocationStatus();
      
      if (locationStatus.enabled && locationStatus.status == LocationPermission.denied) {
        // Request permission
        await QiblahService.requestPermissions();
        // Check status again after permission request
        final updatedStatus = await QiblahService.checkLocationStatus();
        _locationStreamController.sink.add(updatedStatus);
      } else {
        _locationStreamController.sink.add(locationStatus);
      }
    } catch (e) {
      // Handle errors gracefully
      debugPrint('Error checking location status: $e');
      // Add error handling - you could emit an error state or show default UI
    }
  }

  bool isCompassView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Finder'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isCompassView = !isCompassView;
              });
            },
            icon: Icon(isCompassView ? Icons.map : Icons.explore),
            tooltip: isCompassView ? 'Map View' : 'Compass View',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: StreamBuilder<LocationStatus>(
          stream: locationStream,
          builder: (context, snapshot) {
            // Handle loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Checking location status...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Handle error state
            if (snapshot.hasError) {
              return Center(
                child: LocationErrorWidget(
                  title: 'Error',
                  message: 'Error: ${snapshot.error}',
                  onRetry: _checkLocationStatus,
                ),
              );
            }

            // Handle no data state
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final locationStatus = snapshot.data!;

            // Handle location services disabled
            if (!locationStatus.enabled) {
              return Center(
                child: LocationErrorWidget(
                  title: 'Location Services Disabled',
                  message: 'Please enable location services to use Qibla finder.',
                  onRetry: _checkLocationStatus,
                ),
              );
            }

            // Handle different permission states
            switch (locationStatus.status) {
              case LocationPermission.always:
              case LocationPermission.whileInUse:
                return isCompassView 
                    ? const QiblahCompassView() 
                    : const QiblahMapView();
              
              case LocationPermission.denied:
                return Center(
                  child: LocationErrorWidget(
                    title: 'Location Permission Denied',
                    message: 'Location permission is required to calculate Qibla direction.',
                    onRetry: _checkLocationStatus,
                  ),
                );
              
              case LocationPermission.deniedForever:
                return Center(
                  child: LocationErrorWidget(
                    title: 'Location Permission Permanently Denied',
                    message: 'Please enable location permission in app settings.',
                    onRetry: () async {
                      // Open app settings
                      await Geolocator.openAppSettings();
                      await _checkLocationStatus();
                    },
                    buttonText: 'Open Settings',
                  ),
                );
              
              case LocationPermission.unableToDetermine:
                return Center(
                  child: LocationErrorWidget(
                    title: 'Unable to Determine Permission',
                    message: 'Unable to determine location permission status.',
                    onRetry: _checkLocationStatus,
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

/// Reusable widget for displaying location-related errors
class LocationErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final String? buttonText;

  const LocationErrorWidget({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(buttonText ?? 'Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compass view widget
class QiblahCompassView extends StatelessWidget {
  const QiblahCompassView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblahDirection>(
      stream: QiblahService.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                SizedBox(height: 20),
                Text(
                  'Getting compass data...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 60, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  'Compass Error: ${snapshot.error}',
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final qiblahDirection = snapshot.data!;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Compass Container
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Compass background
                      Container(
                        width: 280,
                        height: 280,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      
                      // Qibla direction indicator
                      Transform.rotate(
                        angle: (qiblahDirection.qiblah * (3.14159 / 180)),
                        child: Container(
                          width: 4,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      
                      // Center dot
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                      
                      // North indicator
                      Positioned(
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'N',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Direction info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Qibla Direction',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${qiblahDirection.offset.toStringAsFixed(1)}°',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'Device Heading',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${qiblahDirection.direction.toStringAsFixed(1)}°',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Rotate your device until the green line points upward to face Qibla direction.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Map view widget (placeholder)
class QiblahMapView extends StatelessWidget {
  const QiblahMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 100,
            color: Colors.green,
          ),
          SizedBox(height: 20),
          Text(
            'Map View',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Map integration would go here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}