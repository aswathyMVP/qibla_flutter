# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2024-12-04

### Added
- Initial release of Qibla AR Finder package
- AR View with camera overlay for Android and iOS
- Traditional compass view with Qibla indicator
- 360° panorama view with Kaaba
- Automatic GPS location detection
- Device orientation tracking
- Vertical position warning system
- Cross-platform support (Android with Camera, iOS with ARKit)
- Smooth animations with jitter reduction
- Permission handling for location, camera, and sensors
- Clean architecture with BLoC state management
- Dependency injection with GetIt
- Comprehensive example app

### Features
- Calculate Qibla direction using Haversine formula
- Real-time compass tracking
- AR object placement in Qibla direction
- Tilt detection and warnings
- Location services integration
- Sensor data processing (magnetometer, accelerometer, gyroscope)

### Platform Support
- Android: minSdkVersion 21+
- iOS: 11.0+ (ARKit support)
