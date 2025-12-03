import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ar_qibla_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Schedule permission request after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsAndNavigate();
    });
  }

  Future<void> _requestPermissionsAndNavigate() async {
    // Wait a moment for UI to settle
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Check camera permission
    PermissionStatus cameraStatus = await Permission.camera.status;
    debugPrint('Initial camera permission status: $cameraStatus');
    
    // Check location permission
    PermissionStatus locationStatus = await Permission.location.status;
    debugPrint('Initial location permission status: $locationStatus');
    
    // Request camera permission if not granted
    if (!cameraStatus.isGranted) {
      debugPrint('Requesting camera permission...');
      cameraStatus = await Permission.camera.request();
      debugPrint('Camera permission after request: $cameraStatus');
    }
    
    // Request location permission if not granted
    if (!locationStatus.isGranted) {
      debugPrint('Requesting location permission...');
      locationStatus = await Permission.location.request();
      debugPrint('Location permission after request: $locationStatus');
    }
    
    // If any permission is permanently denied, show settings dialog
    if (cameraStatus.isPermanentlyDenied || locationStatus.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDialog(
          cameraStatus.isPermanentlyDenied,
          locationStatus.isPermanentlyDenied,
        );
      }
      return;
    }
    
    // If permissions are denied but not permanently, show explanation
    if (!cameraStatus.isGranted || !locationStatus.isGranted) {
      if (mounted) {
        _showPermissionExplanationDialog(
          !cameraStatus.isGranted,
          !locationStatus.isGranted,
        );
      }
      return;
    }
    
    // Wait for remaining splash duration
    await Future.delayed(const Duration(milliseconds: 1700));
    
    // Navigate to AR view
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ARQiblaPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _showPermissionDialog(bool cameraDenied, bool locationDenied) {
    String title = 'Permissions Required';
    String message = 'This app needs ';
    
    if (cameraDenied && locationDenied) {
      message += 'camera and location access to show AR Qibla direction. Please enable both permissions in Settings.';
    } else if (cameraDenied) {
      message += 'camera access to show AR Qibla direction. Please enable camera permission in Settings.';
    } else {
      message += 'location access to calculate Qibla direction. Please enable location permission in Settings.';
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Retry permission request
              _requestPermissionsAndNavigate();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
              // After returning from settings, retry
              if (mounted) {
                await Future.delayed(const Duration(milliseconds: 500));
                _requestPermissionsAndNavigate();
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionExplanationDialog(bool cameraDenied, bool locationDenied) {
    String message = 'To use AR Qibla finder, we need:\n\n';
    
    if (cameraDenied) {
      message += '📷 Camera: To show the AR view\n';
    }
    if (locationDenied) {
      message += '📍 Location: To calculate Qibla direction\n';
    }
    
    message += '\nPlease grant these permissions to continue.';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Needed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestPermissionsAndNavigate();
            },
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/qibla.png',
          width: 200,
          height: 300,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
