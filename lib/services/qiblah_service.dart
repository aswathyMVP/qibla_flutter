import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stream_transform/stream_transform.dart' show CombineLatest;
import '../utils/qiblah_utils.dart';

/// Location Status class, contains the GPS status(Enabled or not) and LocationPermission
class LocationStatus {
  final bool enabled;
  final LocationPermission status;

  const LocationStatus(this.enabled, this.status);
}

/// Containing Qiblah, Direction and offset
class QiblahDirection {
  final double qiblah;
  final double direction;
  final double offset;

  const QiblahDirection(this.qiblah, this.direction, this.offset);

  @override
  String toString() =>
      'QiblahDirection(qiblah: $qiblah, direction: $direction, offset: $offset)';
}

/// [QiblahService] is a singleton class that provides access to compass events,
/// check for sensor support in Android, get current location, and get Qibla direction
class QiblahService {
  static const _channel = MethodChannel('ml.medyas.qibla_ar_finder');
  static final _instance = QiblahService._();

  Stream<QiblahDirection>? _qiblahStream;

  QiblahService._();

  factory QiblahService() => _instance;

  /// Check Android device sensor support
  static Future<bool?> androidDeviceSensorSupport() async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod("androidSupportSensor");
    } else {
      return true;
    }
  }

  /// Request Location permission, return LocationPermission object
  static Future<LocationPermission> requestPermissions() =>
      Geolocator.requestPermission();

  /// Get location status: GPS enabled and the permission status with LocationStatus
  static Future<LocationStatus> checkLocationStatus() async {
    final status = await Geolocator.checkPermission();
    final enabled = await Geolocator.isLocationServiceEnabled();
    return LocationStatus(enabled, status);
  }

  /// Provides a stream of QiblahDirection with current compass and Qiblah direction
  /// Direction varies from 0-360, 0 being north.
  /// Qiblah varies from 0-360, offset from direction(North)
  static Stream<QiblahDirection> get qiblahStream {
    _instance._qiblahStream ??= _merge<CompassEvent, Position>(
      FlutterCompass.events!,
      Geolocator.getPositionStream().transform(
        StreamTransformer<Position, Position>.fromHandlers(
          handleData: (Position position, EventSink<Position> sink) {
            sink.add(position);
          },
        ),
      ),
    );
    return _instance._qiblahStream!;
  }

  /// Merge the compass stream with location updates, and calculate the Qiblah direction
  /// return a Stream<QiblaDirection> containing compass and Qiblah direction
  /// Direction varies from 0-360, 0 being north.
  /// Qiblah varies from 0-360, offset from direction(North)
  static Stream<QiblahDirection> _merge<A, B>(
    Stream<A> streamA,
    Stream<B> streamB,
  ) =>
      streamA.combineLatest<B, QiblahDirection>(
        streamB,
        (dir, pos) {
          final position = pos as Position;
          final event = dir as CompassEvent;

          // Calculate the Qiblah offset to North
          final offset = QiblahUtils.getOffsetFromNorth(
            position.latitude,
            position.longitude,
          );

          // Adjust Qiblah direction based on North direction
          final qiblah = (event.heading ?? 0.0) + (360 - offset);

          return QiblahDirection(qiblah, event.heading ?? 0.0, offset);
        },
      );

  /// Close compass stream, and set Qiblah stream to null
  void dispose() {
    _qiblahStream = null;
  }
}
