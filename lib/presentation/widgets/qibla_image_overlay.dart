import 'package:flutter/material.dart';

class QiblaImageOverlay extends StatelessWidget {
  const QiblaImageOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 200),
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Image.asset(
            'assets/images/qibla.png',
            package: 'qibla_ar_finder',
            width: 200,
            height: 290,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
