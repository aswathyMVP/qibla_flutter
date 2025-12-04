import 'package:flutter/material.dart';

/// Global reusable widget for vertical position warning
/// Shows when phone is not held in vertical position
class VerticalPositionWarning extends StatelessWidget {
  final bool animate;

  const VerticalPositionWarning({
    super.key,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: -15.0, end: 15.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: (animate ? value : -value) * 0.0174533, // Convert to radians
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/images/phone_icon.png',
                  package: 'qibla_ar_finder',
                  width: 60,
                  height: 120,
                  color: Colors.green,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.phone_android,
                      size: 120,
                      color: Colors.green,
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Text(
                  'Rotate your phone to a vertical position.\n\n'
                  'Hold it upright so the compass can accurately detect the Qibla direction.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
