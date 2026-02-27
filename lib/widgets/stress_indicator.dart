import 'package:flutter/material.dart';

/// Large circular stress indicator used on the Dashboard.
///
/// Draws a coloured arc that fills proportionally to [stressLevel] (0–100),
/// surrounded by a soft pulsing glow driven by [pulseController].
class StressIndicator extends StatelessWidget {
  /// Current stress value (0–100).
  final int stressLevel;

  /// Human-readable label: "Relaxed", "Normal", or "Stressed"
  final String label;

  /// Colour corresponding to the stress zone.
  final Color color;

  /// Animation controller for the outer glow pulse effect.
  final AnimationController pulseController;

  const StressIndicator({
    super.key,
    required this.stressLevel,
    required this.label,
    required this.color,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        // Pulse size oscillates between 0 and 16 px
        final pulseSize = pulseController.value * 16;

        return Center(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulsing glow ring
                  Container(
                    width: 200 + pulseSize,
                    height: 200 + pulseSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(
                          alpha: 0.06 * (1 - pulseController.value)),
                    ),
                  ),

                  // Middle halo
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.08),
                    ),
                  ),

                  // Circular progress arc
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: stressLevel / 100),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      builder: (context, progress, _) {
                        return CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: color.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          strokeCap: StrokeCap.round,
                        );
                      },
                    ),
                  ),

                  // Centre text: numeric level + label
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: stressLevel),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, _) => Text(
                          '$value',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: color,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'STRESS LEVEL',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Coloured status chip
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
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
