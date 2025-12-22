import 'dart:math';

/// Utility class for Qiblah calculations
class QiblahUtils {
  // Kaaba coordinates
  static const double _kaabaLatitude = 21.4225;
  static const double _kaabaLongitude = 39.8262;

  /// Calculate the offset angle from North to Qiblah direction
  /// Returns the bearing angle from North (0-360 degrees)
  static double getOffsetFromNorth(double latitude, double longitude) {
    return _calculateBearing(latitude, longitude, _kaabaLatitude, _kaabaLongitude);
  }

  /// Calculate bearing between two geographic points using Haversine formula
  /// Returns bearing in degrees (0-360)
  static double _calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = _toRadians(lon2 - lon1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final y = sin(dLon) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

    final bearing = atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Convert radians to degrees
  static double _toDegrees(double radians) {
    return radians * 180 / pi;
  }

  /// Calculate distance between two geographic points using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }
}
