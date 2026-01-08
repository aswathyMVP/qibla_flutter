# Qibla AR Finder

A professional Flutter package for finding Qibla direction using AR, compass, and GPS. Supports both Android and iOS.

## Features

- 🕌 **AR View** - Augmented reality with camera overlay showing Kaaba direction
- 🧭 **Compass View** - Traditional compass with Qibla indicator
- 🌐 **Panorama View** - 360° view with Kaaba
- 📍 **GPS Location** - Automatic location detection
- 📱 **Cross-platform** - Works on Android (Camera AR) and iOS (ARKit)
- ⚠️ **Vertical Warning** - Alerts when device is not held vertically
- 🎯 **Accurate** - Uses Haversine formula for precise bearing calculation
- ⚡ **Pre-Initialization** - Initialize AR during app startup for instant loading

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  qibla_ar_finder:
    git:
      url: https://github.com/yourusername/qibla_ar_finder.git
```

Or for a specific version:

```yaml
dependencies:
  qibla_ar_finder:
    git:
      url: https://github.com/yourusername/qibla_ar_finder.git
      ref: v1.0.0
```

## Platform Setup

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.sensor.accelerometer" />
<uses-feature android:name="android.hardware.sensor.compass" />
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to calculate Qibla direction</string>
<key>NSCameraUsageDescription</key>
<string>Camera is required for AR view</string>
<key>arkit</key>
<string>Required for AR features</string>
```

Minimum iOS version: 11.0 (for ARKit support)

## Usage

### Basic Setup

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qibla_ar_finder/qibla_ar_finder.dart';

void main() {
  // Initialize dependency injection
  configureDependencies();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: QiblaFinderPage(),
    );
  }
}
```

### AR Pre-Initialization (Recommended)

For instant AR loading, initialize AR during app startup:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  configureDependencies();
  
  // Pre-initialize AR (eliminates loading when AR screen opens)
  ARInitializationManager.instance.initialize();
  
  runApp(MyApp());
}
```

**Benefits:**
- ✅ No loading indicator when AR screen opens
- ✅ Better user experience
- ✅ AR ready when user needs it

See [AR Pre-Initialization Guide](AR_PREINITIALIZATION_GUIDE.md) for detailed usage patterns.

### AR View

```dart
class QiblaFinderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ARCubit>()),
        BlocProvider(create: (_) => getIt<TiltCubit>()),
      ],
      child: ARQiblaPage(
        config: ARPageConfig(
          primaryColor: Colors.green,
          showTopBar: true,
          showInstructions: true,
          showCompassIndicators: true,
          moveRightText: 'Turn Right',
          moveLeftText: 'Turn Left',
          message: 'Hold phone vertically',
        ),
      ),
    );
  }
}
```

### Compass View

```dart
class CompassPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<QiblaCubit>(),
      child: QiblaCompassPage(),
    );
  }
}
```

### Panorama View

```dart
class PanoramaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PanoramaKaabaPage();
  }
}
```

## Example

See the [example](example/) folder for a complete working app demonstrating all features.

To run the example:

```bash
cd example
flutter run
```

To run the AR pre-initialization example:

```bash
cd example
flutter run -t lib/main_with_preinitialization.dart
```

See [Pre-Initialization Example Guide](example/PREINITIALIZATION_EXAMPLE.md) for details.

## Documentation

### AR Pre-Initialization Feature

The package now supports pre-initializing AR during app startup for instant loading:

| Document | Description | Audience |
|----------|-------------|----------|
| [📋 Summary](AR_PREINITIALIZATION_SUMMARY.md) | Feature overview and benefits | Everyone |
| [🚀 Quick Start](AR_PREINITIALIZATION_QUICK_START.md) | 5-minute setup guide | Developers |
| [📖 Complete Guide](AR_PREINITIALIZATION_GUIDE.md) | Detailed usage patterns | Developers |
| [🔄 Migration Guide](MIGRATION_TO_PREINITIALIZATION.md) | Upgrade existing projects | Existing Users |
| [🏗️ Architecture](AR_PREINITIALIZATION_ARCHITECTURE.md) | Technical implementation | Advanced Users |
| [💡 Example](example/PREINITIALIZATION_EXAMPLE.md) | Working example walkthrough | Developers |
| [✅ Checklist](AR_PREINITIALIZATION_CHECKLIST.md) | Implementation checklist | Teams |

### Technical Documentation

- 🏗️ [Technical Architecture](ARCORE_TECHNICAL_ARCHITECTURE.md) - AR implementation details
- 📝 [Implementation Summary](ARCORE_IMPLEMENTATION_SUMMARY.md) - Implementation overview

## How It Works

1. **GPS Detection** - Gets user's latitude/longitude using `geolocator`
2. **Qibla Calculation** - Calculates bearing to Kaaba (21.422504°N, 39.826195°E) using Haversine formula
3. **Compass Tracking** - Monitors device heading using magnetometer
4. **AR Rendering** - Positions Kaaba image in calculated direction
5. **Smoothing** - Applies filters to reduce jitter

## Requirements

- Flutter SDK: >=3.0.0
- Dart SDK: >=3.0.0
- Android: minSdkVersion 21
- iOS: 11.0+ (for ARKit)

## Dependencies

- `flutter_bloc` - State management
- `get_it` - Dependency injection
- `geolocator` - GPS location
- `flutter_compass` - Compass/magnetometer
- `sensors_plus` - Accelerometer/gyroscope
- `camera` - Camera for AR (Android)
- `arkit_plugin` - ARKit (iOS)
- `permission_handler` - Runtime permissions

## Permissions

The package requires the following permissions:

- **Location** - To calculate Qibla direction
- **Camera** - For AR view
- **Sensors** - For device orientation

Permissions are requested automatically at runtime.

## Troubleshooting

### GPS not working
- Ensure location permissions are granted
- Go outdoors for better GPS signal
- Check that location services are enabled

### AR view shows black screen
- Verify camera permissions are granted
- Ensure device supports AR (ARKit for iOS)
- Check platform-specific setup is correct

### Compass inaccurate
- Calibrate compass by moving device in figure-8 pattern
- Keep device away from magnetic interference
- Ensure sensor permissions are granted

## License

MIT License - See [LICENSE](LICENSE) file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues or questions, please open an issue on [GitHub](https://github.com/yourusername/qibla_ar_finder/issues).

---

**Made with ❤️ for the Muslim community**
