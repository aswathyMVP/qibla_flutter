# Qibla Integration Guide for Other Projects

## Overview

To use the **QiblaInitializationManager** in any other project and eliminate loading indicators, you need to follow these steps:

## Step 1: Add Package Dependency

### pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  qibla_ar_finder:
    git:
      url: https://github.com/yourusername/qibla_ar_finder.git
      # or path: ../qibla_ar_finder (if local)
```

## Step 2: Configure Dependencies (Required)

### main.dart
```dart
import 'package:flutter/material.dart';
import 'package:qibla_ar_finder/qibla_ar_finder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // STEP 1: Configure package dependencies (REQUIRED!)
  configureDependencies();
  
  // STEP 2: Pre-initialize Qibla (OPTIONAL but recommended)
  QiblaInitializationManager.instance.initialize(
    timeout: Duration(seconds: 45),
    skipLocationIfFailed: true,
  );
  
  runApp(MyApp());
}
```

## Step 3: Use in Your Screens

### Option A: Check Pre-initialization Status
```dart
class MyQiblaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblaInitializationState>(
      stream: QiblaInitializationManager.instance.stateStream,
      initialData: QiblaInitializationManager.instance.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        
        if (state.isInitialized && state.hasLocationPermission) {
          // Qibla is ready! Show compass immediately
          return MyCompassWidget(
            qiblaBearing: state.qiblaBearing!,
            userLocation: state.userLocation,
          );
        }
        
        // Handle other states (loading, error, etc.)
        return MyLoadingWidget();
      },
    );
  }
}
```

### Option B: Simple Check Before Navigation
```dart
class HomeScreen extends StatelessWidget {
  void _openQiblaScreen(BuildContext context) {
    final qiblaState = QiblaInitializationManager.instance.state;
    
    if (qiblaState.isInitialized) {
      // Qibla is ready - navigate immediately
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => MyQiblaScreen(),
      ));
    } else {
      // Not ready - show loading or initialize first
      _showInitializationDialog(context);
    }
  }
  
  void _showInitializationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing Qibla finder...'),
          ],
        ),
      ),
    );
    
    QiblaInitializationManager.instance.initialize().then((success) {
      Navigator.pop(context); // Close dialog
      if (success) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MyQiblaScreen(),
        ));
      }
    });
  }
}
```

### Option C: Use Traditional QiblahService (Fallback)
```dart
class TraditionalQiblaScreen extends StatefulWidget {
  @override
  State<TraditionalQiblaScreen> createState() => _TraditionalQiblaScreenState();
}

class _TraditionalQiblaScreenState extends State<TraditionalQiblaScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblahDirection>(
      stream: QiblahService.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MyCompassWidget(qiblahDirection: snapshot.data!);
        }
        return CircularProgressIndicator(); // This will show loading
      },
    );
  }
}
```

## Step 4: Handle LocationStatus (Your Original Use Case)

### Using QiblaInitializationManager
```dart
class MyLocationStatusScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblaInitializationState>(
      stream: QiblaInitializationManager.instance.stateStream,
      initialData: QiblaInitializationManager.instance.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        
        // Use the cached LocationStatus from pre-initialization
        if (state.locationStatus != null) {
          return _buildLocationStatusUI(state.locationStatus!);
        }
        
        // Fallback to manual check
        return FutureBuilder<LocationStatus>(
          future: QiblahService.checkLocationStatus(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildLocationStatusUI(snapshot.data!);
            }
            return CircularProgressIndicator();
          },
        );
      },
    );
  }
  
  Widget _buildLocationStatusUI(LocationStatus status) {
    if (!status.enabled) {
      return Text('Location services disabled');
    }
    
    switch (status.status) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return Text('Location permission granted');
      case LocationPermission.denied:
        return Text('Location permission denied');
      // ... handle other cases
    }
  }
}
```

## Complete Integration Checklist

### ✅ Required Steps
1. **Add package dependency** in `pubspec.yaml`
2. **Call `configureDependencies()`** in `main()` (REQUIRED!)
3. **Use QiblaInitializationManager or QiblahService** in your screens

### ✅ Optional Steps (for best performance)
4. **Call `QiblaInitializationManager.instance.initialize()`** in `main()`
5. **Check initialization state** before showing Qibla screens
6. **Handle different initialization states** (loading, error, success)

## Minimal Integration (Just LocationStatus)

If you only need LocationStatus checking:

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies(); // REQUIRED!
  runApp(MyApp());
}

// your_screen.dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LocationStatus>(
      future: QiblahService.checkLocationStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        
        if (snapshot.hasData) {
          final status = snapshot.data!;
          // Use LocationStatus as before
          return MyLocationStatusWidget(status: status);
        }
        
        return Text('Error checking location status');
      },
    );
  }
}
```

## Advanced Integration (Pre-initialized)

For instant loading with no loading indicators:

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies(); // REQUIRED!
  
  // Pre-initialize for instant loading
  QiblaInitializationManager.instance.initialize(
    timeout: Duration(seconds: 45),
    skipLocationIfFailed: true,
  );
  
  runApp(MyApp());
}

// your_screen.dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = QiblaInitializationManager.instance.state;
    
    if (state.isInitialized) {
      // Instant display - no loading!
      return MyQiblaCompass(
        qiblaBearing: state.qiblaBearing!,
        locationStatus: state.locationStatus!,
      );
    }
    
    // Handle other states...
    return MyLoadingWidget();
  }
}
```

## Summary

### What You MUST Do:
1. **Add package dependency**
2. **Call `configureDependencies()` in main()** ← This is REQUIRED!

### What You CAN Do (Optional):
3. **Call `QiblaInitializationManager.instance.initialize()` in main()** ← For instant loading
4. **Use pre-initialized state in your screens** ← For best performance

### Result:
- **Minimal**: LocationStatus works as before (with loading)
- **Optimized**: LocationStatus + Qibla work instantly (no loading)

The key insight is that **`configureDependencies()` is required**, but **pre-initialization is optional** for better performance.