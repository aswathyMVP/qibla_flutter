import 'package:flutter/services.dart';

class NativeARService {
  static const platform = MethodChannel('com.example.qibla_ar_finder/ar');

  static Future<void> startARView(double qiblaBearing) async {
    try {
      await platform.invokeMethod('startARView', {
        'qibla_bearing': qiblaBearing,
      });
    } on PlatformException catch (e) {
      print('Failed to start AR view: ${e.message}');
    }
  }
}
