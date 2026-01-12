import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qibla_ar_finder/qibla_ar_finder.dart';

/// Pre-initialized Qibla Screen using QiblaInitializationManager
/// 
/// This screen uses the same pre-initialization approach as AR,
/// eliminating loading indicators when the screen opens.
class PreinitializedQiblaScreen extends StatefulWidget {
  const PreinitializedQiblaScreen({super.key});

  @override
  State<PreinitializedQiblaScreen> createState() => _PreinitializedQiblaScreenState();
}

class _PreinitializedQiblaScreenState extends State<PreinitializedQiblaScreen> {
  bool isCompassView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Finder (Pre-initialized)'),
        centerTitle: true,
        backgroundColor: Colors.teal,
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
              Colors.teal.shade50,
              Colors.white,
            ],
          ),
        ),
        child: StreamBuilder<QiblaInitializationState>(
          stream: QiblaInitializationManager.instance.stateStream,
          initialData: QiblaInitializationManager.instance.state,
          builder: (context, snapshot) {
            final state = snapshot.data!;
            
            // Check if Qibla is pre-initialized
            if (state.isInitialized && state.hasLocationPermission) {
              // Qibla is ready! Show compass immediately with no loading
              return isCompassView 
                  ? PreinitializedQiblahCompassView(
                      qiblaBearing: state.qiblaBearing!,
                      userLocation: state.userLocation,
                    )
                  : const QiblahMapView();
            }
            
            // Handle different initialization states
            if (state.isInitializing) {
              return _buildInitializingUI();
            }
            
            if (state.hasFailed) {
              return _buildErrorUI(state.errorMessage ?? 'Initialization failed');
            }
            
            // Not initialized - check location status
            if (state.locationStatus != null) {
              return _buildLocationStatusUI(state.locationStatus!);
            }
            
            // Fallback to manual initialization
            return _buildManualInitializationUI();
          },
        ),
      ),
    );
  }

  Widget _buildInitializingUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
          SizedBox(height: 20),
          Text(
            'Initializing Qibla finder...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorUI(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Initialization Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                QiblaInitializationManager.instance.reset();
                QiblaInitializationManager.instance.initialize();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatusUI(LocationStatus locationStatus) {
    if (!locationStatus.enabled) {
      return _buildLocationErrorWidget(
        'Location Services Disabled',
        'Please enable location services to use Qibla finder.',
        () async {
          // Try to initialize again
          await QiblaInitializationManager.instance.initialize();
        },
      );
    }

    switch (locationStatus.status) {
      case LocationPermission.denied:
        return _buildLocationErrorWidget(
          'Location Permission Denied',
          'Location permission is required to calculate Qibla direction.',
          () async {
            await QiblaInitializationManager.instance.initialize();
          },
        );
      
      case LocationPermission.deniedForever:
        return _buildLocationErrorWidget(
          'Location Permission Permanently Denied',
          'Please enable location permission in app settings.',
          () async {
            await Geolocator.openAppSettings();
            await QiblaInitializationManager.instance.initialize();
          },
          buttonText: 'Open Settings',
        );
      
      case LocationPermission.unableToDetermine:
        return _buildLocationErrorWidget(
          'Unable to Determine Permission',
          'Unable to determine location permission status.',
          () async {
            await QiblaInitializationManager.instance.initialize();
          },
        );
      
      default:
        return _buildManualInitializationUI();
    }
  }

  Widget _buildLocationErrorWidget(
    String title,
    String message,
    VoidCallback onRetry, {
    String? buttonText,
  }) {
    return Center(
      child: Padding(
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
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInitializationUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore,
              size: 100,
              color: Colors.teal.shade300,
            ),
            const SizedBox(height: 20),
            const Text(
              'Qibla Finder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Initialize Qibla finder to get started',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                QiblaInitializationManager.instance.initialize();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Initialize Qibla Finder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-initialized compass view that shows immediately without loading
class PreinitializedQiblahCompassView extends StatelessWidget {
  final double qiblaBearing;
  final LocationData? userLocation;

  const PreinitializedQiblahCompassView({
    super.key,
    required this.qiblaBearing,
    this.userLocation,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblahDirection>(
      stream: QiblahService.qiblahStream,
      builder: (context, snapshot) {
        // Use pre-calculated bearing if stream data is not available yet
        final qiblahDirection = snapshot.data ?? QiblahDirection(
          qiblaBearing, // Use pre-calculated bearing
          0.0, // Default device heading
          qiblaBearing, // Use pre-calculated offset
        );

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pre-initialization success indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on, color: Colors.green.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Pre-initialized - No Loading!',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Compass Container
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.teal, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withValues(alpha: 0.3),
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
                                color: Colors.teal,
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
                              color: Colors.teal,
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
                    
                    // Real-time update indicator
                    if (snapshot.hasData)
                      Positioned(
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
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
                        color: Colors.grey.withValues(alpha: 0.2),
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
                                  color: Colors.teal,
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
                      if (userLocation != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Location: ${userLocation!.latitude.toStringAsFixed(4)}, '
                              '${userLocation!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.teal),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Rotate your device until the teal line points upward to face Qibla direction.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.teal,
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
            color: Colors.teal,
          ),
          SizedBox(height: 20),
          Text(
            'Map View',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
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