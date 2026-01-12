# Location Permission Compatibility

## Overview

The `qibla_ar_finder` package uses two different permission systems that coexist without conflicts:

## Permission Systems

### 1. AR Initialization (permission_handler)

**Used by:**
- `ARInitializationManager`
- `ARCubit`

**Purpose:** Pre-initialization of AR resources

**Permissions:**
- Camera: `Permission.camera`
- Location: `Permission.location`

**Benefits:**
- Unified permission handling across platforms
- Consistent permission states
- Works well with AR pre-initialization

### 2. QiblahService (geolocator)

**Used by:**
- `QiblahService.checkLocationStatus()`
- `QiblahService.requestPermissions()`

**Purpose:** Compass and Qibla direction functionality

**Permissions:**
- Location: `Geolocator.checkPermission()`
- Location Services: `Geolocator.isLocationServiceEnabled()`

**Benefits:**
- Direct integration with geolocator
- Provides detailed location service status
- Optimized for location streaming

## Why Two Systems?

1. **Different Use Cases:**
   - AR initialization needs camera + location permissions
   - QiblahService only needs location permissions

2. **Different Requirements:**
   - AR pre-initialization benefits from `permission_handler`'s unified API
   - QiblahService is tightly integrated with `geolocator` for streaming

3. **Backward Compatibility:**
   - QiblahService maintains its existing API
   - AR initialization is a new feature with its own requirements

## Compatibility

Both systems work together without conflicts:

- They use different underlying APIs
- They don't interfere with each other's permission states
- Both can request location permissions independently
- The user experience is seamless

## Usage

### For AR Features
```dart
// Use ARInitializationManager
await ARInitializationManager.instance.initialize();

// Or use ARCubit directly
context.read<ARCubit>().initializeAR();
```

### For Compass Features
```dart
// Use QiblahService
final status = await QiblahService.checkLocationStatus();
final stream = QiblahService.qiblahStream;
```

## Best Practices

1. **Don't mix systems** - Use ARInitializationManager for AR, QiblahService for compass
2. **Both are safe** - You can use both in the same app without issues
3. **Permission requests are handled** - Both systems handle their own permission requests
4. **No conflicts** - The systems don't interfere with each other

## Summary

The coexistence of two permission systems is intentional and beneficial:
- AR initialization remains fast and reliable
- QiblahService maintains its proven functionality
- No breaking changes for existing users
- Clean separation of concerns