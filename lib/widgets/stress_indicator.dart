import 'package:flutter/material.dart';

/// Large circular stress indicator used on the Dashboard.
///
/// Draws a coloured arc that fills proportionally to [stressLevel] (0–100),
/// with an animated number counter and friendly status label.
class StressIndicator extends StatelessWidget {
  /// Current stress value (0–100).
  final int stressLevel;

  /// Human-readable label: e.g. "Santai 😊", "Normal 😐", "Tegang 😟"
  final String label;

  /// Colour corresponding to the stress zone.
  final Color color;

  const StressIndicator({
    super.key,
    required this.stressLevel,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer static glow ring
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.04),
                ),
              ),

              // Middle halo
              Container(
                width: 192,
                height: 192,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.09),
                ),
              ),

              // Circular progress arc
              SizedBox(
                width: 170,
                height: 170,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: stressLevel / 100),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  builder: (context, progress, _) {
                    return CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 13,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),

              // Centre text: numeric level + friendly label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: stressLevel),
                    duration: const Duration(milliseconds: 700),
                    builder: (context, value, _) => Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.bold,
                        color: color,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Indeks Stres',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.4,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Coloured status chip with emoji
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
