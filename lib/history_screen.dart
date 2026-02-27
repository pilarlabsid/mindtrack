import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'services/ble_service.dart';

/// History screen – shows a line chart of stress levels over time.
///
/// Uses real BLE history data when available.
/// Falls back to generated dummy data when history is empty.
class HistoryScreen extends StatefulWidget {
  final BleService bleService;
  const HistoryScreen({super.key, required this.bleService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  BleService get _ble => widget.bleService;

  @override
  void initState() {
    super.initState();
    _ble.addListener(_refresh);
  }

  @override
  void dispose() {
    _ble.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  /// Build chart spots from BLE history or dummy data
  List<FlSpot> _buildSpots() {
    final history = _ble.history;

    if (history.isNotEmpty) {
      // Use real BLE data — plot stress index over sequential time
      // Group by minute, take average if multiple readings same minute
      final spots = <FlSpot>[];
      final firstTs = history.first.timestamp;

      for (int i = 0; i < history.length; i++) {
        final minutesSinceStart =
            history[i].timestamp.difference(firstTs).inSeconds / 60.0;
        spots.add(FlSpot(minutesSinceStart, history[i].stressIndex.toDouble()));
      }
      return spots;
    }

    // Fallback: generate 24 hours of dummy data
    return _generateDummyHistory();
  }

  bool get _isUsingRealData => _ble.history.isNotEmpty;

  static List<FlSpot> _generateDummyHistory() {
    final rng = Random(42);
    return List.generate(24, (i) {
      double base = 30.0;
      if (i >= 9 && i <= 12) base = 55.0;
      if (i >= 13 && i <= 15) base = 45.0;
      if (i >= 18 && i <= 21) base = 65.0;
      if (i >= 22 || i <= 5) base = 20.0;
      final value = (base + rng.nextDouble() * 20 - 10).clamp(5.0, 95.0);
      return FlSpot(i.toDouble(), value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = _buildSpots();
    final isReal = _isUsingRealData;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stress History',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              isReal
                  ? '${_ble.history.length} readings recorded'
                  : 'Sample data (last 24 hours)',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Data source badge
              if (!isReal)
                _DataSourceBadge(isReal: isReal),

              // Summary chips
              Row(
                children: [
                  _SummaryChip(
                    label: 'Average',
                    value: '${_average(spots).toStringAsFixed(0)}%',
                    color: const Color(0xFF6C63FF),
                  ),
                  const SizedBox(width: 12),
                  _SummaryChip(
                    label: 'Peak',
                    value:
                        '${spots.map((s) => s.y).reduce(max).toStringAsFixed(0)}%',
                    color: const Color(0xFFF44336),
                  ),
                  const SizedBox(width: 12),
                  _SummaryChip(
                    label: 'Min',
                    value:
                        '${spots.map((s) => s.y).reduce(min).toStringAsFixed(0)}%',
                    color: const Color(0xFF4CAF50),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Chart card
              Container(
                padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 16),
                      child: Text(
                        isReal
                            ? 'Stress Level (live session)'
                            : 'Stress Level Over Time',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 240,
                      child: LineChart(
                          _buildChartData(spots, isReal)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Legend
              _buildLegend(),
              const SizedBox(height: 24),

              // Hourly / reading list
              Text(
                isReal ? 'Recent Readings' : 'Hourly Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              if (isReal)
                ..._buildRealDataList()
              else
                ..._buildHourlyList(spots),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chart ─────────────────────────────────────────────────────────────

  LineChartData _buildChartData(List<FlSpot> spots, bool isReal) {
    final maxX = spots.isEmpty ? 23.0 : spots.last.x;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade100,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            reservedSize: 34,
            getTitlesWidget: (val, meta) => Text(
              val.toInt().toString(),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: isReal ? null : 4,
            getTitlesWidget: (val, meta) {
              if (!isReal) {
                final hour = val.toInt();
                if (hour % 4 != 0) return const SizedBox.shrink();
                return Text(_formatHour(hour),
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade500));
              }
              // For real data show minutes
              return Text(
                '${val.toStringAsFixed(0)}m',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              );
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: maxX < 1 ? 1 : maxX,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: const Color(0xFF6C63FF),
          barWidth: 2.5,
          dotData: FlDotData(show: spots.length < 30),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.3),
                const Color(0xFF6C63FF).withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: 30,
            color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              labelResolver: (_) => 'Relaxed',
              style: const TextStyle(fontSize: 9, color: Color(0xFF4CAF50)),
            ),
          ),
          HorizontalLine(
            y: 60,
            color: const Color(0xFFFF9800).withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              labelResolver: (_) => 'Normal',
              style: const TextStyle(fontSize: 9, color: Color(0xFFFF9800)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: const Color(0xFF4CAF50), label: '0–30 Relaxed'),
        const SizedBox(width: 16),
        _LegendItem(color: const Color(0xFFFF9800), label: '31–60 Normal'),
        const SizedBox(width: 16),
        _LegendItem(color: const Color(0xFFF44336), label: '61–100 Stressed'),
      ],
    );
  }

  /// Build list from real BLE history (most recent first, capped at 50).
  List<Widget> _buildRealDataList() {
    final items = _ble.history.reversed.take(50).toList();
    return items.map((data) {
      final val = data.stressIndex;
      Color statusColor;
      String statusLabel;
      if (val <= 30) {
        statusColor = const Color(0xFF4CAF50);
        statusLabel = 'Relaxed';
      } else if (val <= 60) {
        statusColor = const Color(0xFFFF9800);
        statusLabel = 'Normal';
      } else {
        statusColor = const Color(0xFFF44336);
        statusLabel = 'Stressed';
      }
      final ts = data.timestamp;
      final time =
          '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';

      return _ReadingRow(
        time: time,
        value: val,
        statusLabel: statusLabel,
        statusColor: statusColor,
      );
    }).toList();
  }

  List<Widget> _buildHourlyList(List<FlSpot> spots) {
    return spots.map((spot) {
      final hour = spot.x.toInt();
      final val = spot.y.toInt();
      Color statusColor;
      String statusLabel;
      if (val <= 30) {
        statusColor = const Color(0xFF4CAF50);
        statusLabel = 'Relaxed';
      } else if (val <= 60) {
        statusColor = const Color(0xFFFF9800);
        statusLabel = 'Normal';
      } else {
        statusColor = const Color(0xFFF44336);
        statusLabel = 'Stressed';
      }
      return _ReadingRow(
        time: _formatHour(hour),
        value: val,
        statusLabel: statusLabel,
        statusColor: statusColor,
      );
    }).toList();
  }

  double _average(List<FlSpot> spots) =>
      spots.isEmpty ? 0 : spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;

  String _formatHour(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Reusable sub-widgets
// ═══════════════════════════════════════════════════════════════════════════

class _DataSourceBadge extends StatelessWidget {
  final bool isReal;
  const _DataSourceBadge({required this.isReal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFFFF9800)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sample data. Connect your device to see real history.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  final String time;
  final int value;
  final String statusLabel;
  final Color statusColor;
  const _ReadingRow({
    required this.time,
    required this.value,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 100,
                backgroundColor: statusColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$value%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
