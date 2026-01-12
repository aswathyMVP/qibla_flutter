import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qibla_ar_finder/qibla_ar_finder.dart';

/// Optimized Qibla Screen with reduced loading time
/// 
/// This version implements several optimization strategies:
/// 1. Pre-cached location data
/// 2. Faster permission checking
/// 3. Progressive UI loading
/// 4. Cached Qibla calculations
/// 5. Immediate compass display with placeholder data
class OptimizedQiblaScreen extends StatefulWidget {
  const OptimizedQiblaScreen({super.key});

  @override
  State<OptimizedQiblaScreen> createState() => _OptimizedQiblaScreenState();
}

class _OptimizedQiblaScreenState extends State<OptimizedQiblaScreen> {
  // Cache for faster subsequent loads
  static LocationStatus? _cachedLocationStatus;
  static QiblahDirection? _lastKnownQiblaDirection;
  static DateTime? _lastLocationCheck;
  
  final _locationStreamController = StreamController<LocationStatus>.broadcast();
  bool _isInitializing = true;
  bool _showProgressiveUI = false;
  
  Stream<LocationStatus> get locationStream => _locationStreamController.stream;

  @override
  void initState() {
    super.initState();
    _initializeWithOptimizations();
  }

  @override
  void dispose() {
    _locationStreamController.close();
    QiblahService().dispose();
    super.dispose();
  }

  /// Optimized initialization with multiple strategies
  Future<void> _initializeWithOptimizations() async {
    // Strategy 1: Show progressive UI immediately
    setState(() {
      _showProgressiveUI = true;
    });

    // Strategy 2: Use cached data if recent (within 5 minutes)
    if (_cachedLocationStatus != null && 
        _lastLocationCheck != null &&
        DateTime.now().difference(_lastLocationCheck!).inMinutes < 5) {
      
      debugPrint('Using cached location status');
      _locationStreamController.sink.add(_cachedLocationStatus!);
      setState(() {
        _isInitializing = false;
      });
      return;
    }

    // Strategy 3: Fast permission check without full location acquisition
    await _quickLocationCheck();
  }

  /// Quick location permission check without GPS acquisition
  Future<void> _quickLocationCheck() async {
    try {
      // This is much faster than full location acquisition
      final locationStatus = await QiblahService.checkLocationStatus();
      
      // Cache the result
      _cachedLocationStatus = locationStatus;
      _lastLocationCheck = DateTime.now();
      
      if (locationStatus.enabled && locationStatus.status == LocationPermission.denied) {
        // Request permission quickly
        await QiblahService.requestPermissions();
        final updatedStatus = await QiblahService.checkLocationStatus();
        _cachedLocationStatus = updatedStatus;
        _locationStreamController.sink.add(updatedStatus);
      } else {
        _locationStreamController.sink.add(locationStatus);
      }
      
      setState(() {
        _isInitializing = false;
      });
      
    } catch (e) {
      debugPrint('Error in quick location check: $e');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  /// Force refresh location status
  Future<void> _refreshLocationStatus() async {
    setState(() {
      _isInitializing = true;
    });
    
    // Clear cache to force fresh check
    _cachedLocationStatus = null;
    _lastLocationCheck = null;
    
    await _quickLocationCheck();
  }

  bool isCompassView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Finder (Optimized)'),
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
          IconButton(
            onPressed: _refreshLocationStatus,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
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
        child: _buildOptimizedBody(),
      ),
    );
  }

  Widget _buildOptimizedBody() {
    // Strategy 4: Show progressive UI while loading
    if (_isInitializing && _showProgressiveUI) {
      return _buildProgressiveLoadingUI();
    }

    return StreamBuilder<LocationStatus>(
      stream: locationStream,
      initialData: _cachedLocationStatus, // Use cached data immediately
      builder: (context, snapshot) {
        // Minimal loading state since we use cached data
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return _buildMinimalLoadingUI();
        }

        if (snapshot.hasError) {
          return Center(
            child: LocationErrorWidget(
              title: 'Error',
              message: 'Error: ${snapshot.error}',
              onRetry: _refreshLocationStatus,
            ),
          );
        }

        if (!snapshot.hasData) {
          return _buildMinimalLoadingUI();
        }

        final locationStatus = snapshot.data!;

        if (!locationStatus.enabled) {
          return Center(
            child: LocationErrorWidget(
              title: 'Location Services Disabled',
              message: 'Please enable location services to use Qibla finder.',
              onRetry: _refreshLocationStatus,
            ),
          );
        }

        switch (locationStatus.status) {
          case LocationPermission.always:
          case LocationPermission.whileInUse:
            return isCompassView 
                ? OptimizedQiblahCompassView(lastKnownDirection: _lastKnownQiblaDirection)
                : const QiblahMapView();
          
          case LocationPermission.denied:
            return Center(
              child: LocationErrorWidget(
                title: 'Location Permission Denied',
                message: 'Location permission is required to calculate Qibla direction.',
                onRetry: _refreshLocationStatus,
              ),
            );
          
          case LocationPermission.deniedForever:
            return Center(
              child: LocationErrorWidget(
                title: 'Location Permission Permanently Denied',
                message: 'Please enable location permission in app settings.',
                onRetry: () async {
                  await QiblahService.requestPermissions();
                  await _refreshLocationStatus();
                },
                buttonText: 'Open Settings',
              ),
            );
          
          case LocationPermission.unableToDetermine:
            return Center(
              child: LocationErrorWidget(
                title: 'Unable to Determine Permission',
                message: 'Unable to determine location permission status.',
                onRetry: _refreshLocationStatus,
              ),
            );
        }
      },
    );
  }

  /// Progressive loading UI that shows immediately
  Widget _buildProgressiveLoadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Show compass skeleton immediately
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade200, width: 3),
              color: Colors.grey.shade100,
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Initializing...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            backgroundColor: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Checking permissions...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Minimal loading UI for quick transitions
  Widget _buildMinimalLoadingUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading...',
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

/// Optimized compass view with faster loading
class OptimizedQiblahCompassView extends StatefulWidget {
  final QiblahDirection? lastKnownDirection;

  const OptimizedQiblahCompassView({
    super.key,
    this.lastKnownDirection,
  });

  @override
  State<OptimizedQiblahCompassView> createState() => _OptimizedQiblahCompassViewState();
}

class _OptimizedQiblahCompassViewState extends State<OptimizedQiblahCompassView> {
  QiblahDirection? _currentDirection;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    // Use last known direction immediately if available
    if (widget.lastKnownDirection != null) {
      _currentDirection = widget.lastKnownDirection;
      _isFirstLoad = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblahDirection>(
      stream: QiblahService.qiblahStream,
      initialData: widget.lastKnownDirection, // Show cached data immediately
      builder: (context, snapshot) {
        // Strategy: Show last known direction while loading new data
        if (snapshot.connectionState == ConnectionState.waiting && _currentDirection != null) {
          return _buildCompassUI(_currentDirection!, isLoading: true);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCompass();
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
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isFirstLoad = true;
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return _buildLoadingCompass();
        }

        final qiblahDirection = snapshot.data!;
        
        // Cache the direction for next time
        _currentDirection = qiblahDirection;
        _OptimizedQiblaScreenState._lastKnownQiblaDirection = qiblahDirection;
        
        if (_isFirstLoad) {
          _isFirstLoad = false;
        }

        return _buildCompassUI(qiblahDirection);
      },
    );
  }

  Widget _buildLoadingCompass() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade200, width: 3),
              color: Colors.grey.shade50,
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      strokeWidth: 4,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Getting compass data...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassUI(QiblahDirection qiblahDirection, {bool isLoading = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Compass Container
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLoading ? Colors.green.shade300 : Colors.green, 
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: isLoading ? 0.2 : 0.3),
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLoading ? Colors.grey.shade50 : Colors.white,
                        ),
                      ),
                      
                      // Qibla direction indicator
                      Transform.rotate(
                        angle: (qiblahDirection.qiblah * (3.14159 / 180)),
                        child: Container(
                          width: 4,
                          height: 140,
                          decoration: BoxDecoration(
                            color: isLoading ? Colors.green.shade300 : Colors.green,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      
                      // Center dot
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLoading ? Colors.green.shade300 : Colors.green,
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
                
                // Loading indicator overlay
                if (isLoading)
                  Positioned(
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Updating...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isLoading ? Colors.green.shade300 : Colors.green,
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
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isLoading ? Colors.blue.shade300 : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Using cached data while updating...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
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