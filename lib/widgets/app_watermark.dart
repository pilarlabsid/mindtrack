import 'package:flutter/material.dart';

/// Widget Watermark standar untuk seluruh aplikasi MindTrack.
/// Digunakan di bagian bawah halaman untuk branding yang konsisten.
class AppWatermark extends StatelessWidget {
  final Color? color;
  const AppWatermark({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? Colors.grey.shade400;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monitor_heart_outlined, size: 14, color: textColor.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(
                'MindTrack Wearable Pro',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Powered by Pilar Labs • v1.2.0',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.0,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
