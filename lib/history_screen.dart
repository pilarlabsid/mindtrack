import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/sensor_data.dart';
import 'services/ble_service.dart';
import 'widgets/app_watermark.dart';

/// Riwayat Screen – Menampilkan tren kesehatan pengguna dari waktu ke waktu.
///
/// Tampilan dioptimalkan agar data historis yang banyak tetap terlihat ringkas
/// dan mudah dipindai menggunakan tata letak grid dan ringkasan cerdas.
class HistoryScreen extends StatefulWidget {
  final BleService bleService;
  const HistoryScreen({super.key, required this.bleService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum HistoryMetric { stress, heartRate, hrv, activity, temperature }

enum TimeRange { day, week, month }

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryMetric _selectedMetric = HistoryMetric.stress;
  TimeRange _selectedRange = TimeRange.day;
  bool _isExpanded = false;

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

  bool get _isUsingRealData => _ble.history.isNotEmpty;

  // ── Data Processing ───────────────────────────────────────────────────────

  List<FlSpot> _buildSpots() {
    final history = _ble.history;
    if (history.isNotEmpty && _selectedRange == TimeRange.day) {
      final spots = <FlSpot>[];
      final firstTs = history.first.timestamp;

      for (int i = 0; i < history.length; i++) {
        final minutesSinceStart =
            history[i].timestamp.difference(firstTs).inSeconds / 60.0;
        double val = _getMetricValue(history[i]);
        spots.add(FlSpot(minutesSinceStart, val));
      }
      return spots;
    }
    return _generateDummyHistory();
  }

  double _getMetricValue(SensorData data) {
    switch (_selectedMetric) {
      case HistoryMetric.stress:
        return data.stressIndex.toDouble();
      case HistoryMetric.heartRate:
        return data.heartRate.toDouble();
      case HistoryMetric.hrv:
        return data.hrv.toDouble();
      case HistoryMetric.activity:
        return data.motionScore.toDouble();
      case HistoryMetric.temperature:
        return data.temperature;
    }
  }

  List<FlSpot> _generateDummyHistory() {
    final seed = 42 + _selectedMetric.index + (_selectedRange.index * 10);
    final rng = Random(seed);

    int count;
    switch (_selectedRange) {
      case TimeRange.day:
        count = 24;
        break;
      case TimeRange.week:
        count = 7;
        break;
      case TimeRange.month:
        count = 30;
        break;
    }

    return List.generate(count, (i) {
      double base;
      double variance;
      switch (_selectedMetric) {
        case HistoryMetric.stress:
          base = 35;
          variance = 30;
          break;
        case HistoryMetric.heartRate:
          base = 70;
          variance = 15;
          break;
        case HistoryMetric.hrv:
          base = 25;
          variance = 10;
          break;
        case HistoryMetric.activity:
          base = 20;
          variance = 40;
          break;
        case HistoryMetric.temperature:
          base = 36.2;
          variance = 0.8;
          break;
      }
      final val = base + rng.nextDouble() * variance;
      return FlSpot(i.toDouble(), val);
    });
  }

  Color get _metricColor {
    switch (_selectedMetric) {
      case HistoryMetric.stress:
        return const Color(0xFF6C63FF);
      case HistoryMetric.heartRate:
        return const Color(0xFFF44336);
      case HistoryMetric.hrv:
        return const Color(0xFF7C4DFF);
      case HistoryMetric.activity:
        return const Color(0xFF4CAF50);
      case HistoryMetric.temperature:
        return const Color(0xFFFF9800);
    }
  }

  String get _metricUnit {
    switch (_selectedMetric) {
      case HistoryMetric.stress:
        return '%';
      case HistoryMetric.heartRate:
        return 'BPM';
      case HistoryMetric.hrv:
        return 'ms';
      case HistoryMetric.activity:
        return '/100';
      case HistoryMetric.temperature:
        return '°C';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = _buildSpots();
    final isReal = _isUsingRealData && _selectedRange == TimeRange.day;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Riwayat Kesehatan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (!_isUsingRealData)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: const Chip(
                label: Text('Simulasi',
                    style: TextStyle(fontSize: 10, color: Colors.orange)),
                backgroundColor: Color(0xFFFFF3E0),
                side: BorderSide.none,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildMetricTabs(),
              const SizedBox(height: 12),
              _buildTimeRangeSelector(),
              const SizedBox(height: 24),
              _buildSummaryHeader(spots),
              const SizedBox(height: 16),
              _buildChartCard(spots, isReal),
              const SizedBox(height: 32),

              // ── Bagian Daftar Data (Compact Grid) ─────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isReal ? 'Data Sesi Terkini' : _getListTitle(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  if ((isReal ? _ble.history.length : spots.length) > 6)
                    TextButton(
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                      child: Text(_isExpanded ? 'Sembunyikan' : 'Lihat Semua',
                          style: const TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildCompactGrid(spots, isReal),
              const SizedBox(height: 12),
              const AppWatermark(),
            ],
          ),
        ),
      ),
    );
  }

  String _getListTitle() {
    switch (_selectedRange) {
      case TimeRange.day:
        return 'Ringkasan Per Jam';
      case TimeRange.week:
        return 'Ringkasan Harian';
      case TimeRange.month:
        return 'Ringkasan Harian';
    }
  }

  Widget _buildMetricTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: HistoryMetric.values.map((m) {
          final isSelected = _selectedMetric == m;
          final color = _getMetricColorFor(m);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(_getMetricLabelFor(m)),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              selectedColor: color,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.white,
              onSelected: (val) {
                if (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedMetric = m);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: TimeRange.values.map((r) {
          final isSelected = _selectedRange == r;
          String label;
          switch (r) {
            case TimeRange.day:
              label = 'Hari';
              break;
            case TimeRange.week:
              label = 'Minggu';
              break;
            case TimeRange.month:
              label = 'Bulan';
              break;
          }
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedRange = r;
                  _isExpanded = false; // Reset expansion on range change
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _metricColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryHeader(List<FlSpot> spots) {
    if (spots.isEmpty) return const SizedBox();
    final values = spots.map((s) => s.y).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final peak = values.reduce(max);
    final minVal = values.reduce(min);

    return Row(
      children: [
        _CompactStat(
          label: 'Rata-rata',
          value: avg.toStringAsFixed(
              avg < 10 && _selectedMetric == HistoryMetric.temperature ? 1 : 0),
          unit: _metricUnit,
          color: _metricColor,
        ),
        const SizedBox(width: 12),
        _CompactStat(
          label: 'Puncak',
          value: peak.toStringAsFixed(
              peak < 10 && _selectedMetric == HistoryMetric.temperature ? 1 : 0),
          unit: _metricUnit,
          color: Colors.redAccent,
        ),
        const SizedBox(width: 12),
        _CompactStat(
          label: 'Terendah',
          value: minVal.toStringAsFixed(
              minVal < 10 && _selectedMetric == HistoryMetric.temperature
                  ? 1
                  : 0),
          unit: _metricUnit,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildChartCard(List<FlSpot> spots, bool isReal) {
    String metricName;
    switch (_selectedMetric) {
      case HistoryMetric.stress: metricName = 'Tingkat Stres'; break;
      case HistoryMetric.heartRate: metricName = 'Detak Jantung'; break;
      case HistoryMetric.hrv: metricName = 'HRV'; break;
      case HistoryMetric.activity: metricName = 'Aktivitas'; break;
      case HistoryMetric.temperature: metricName = 'Suhu Tubuh'; break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 24, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 20),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                      color: _metricColor, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tren $metricName',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: LineChart(_buildChartData(spots, isReal)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<FlSpot> spots, bool isReal) {
    final maxX = spots.isEmpty ? 1.0 : spots.last.x;
    final range = _getYRange();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.shade50, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (val, meta) => Text(
              val.toInt().toString(),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _getBottomInterval(maxX),
            getTitlesWidget: (val, meta) {
              if (val < 0 || val > maxX) return const SizedBox.shrink();
              String text = _getBottomTitleText(val, isReal);
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(text,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: maxX,
      minY: range.$1,
      maxY: range.$2,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _metricColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                _metricColor.withValues(alpha: 0.2),
                _metricColor.withValues(alpha: 0)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1A1A2E),
          getTooltipItems: (items) => items
              .map((i) => LineTooltipItem(
                    '${i.y.toStringAsFixed(_selectedMetric == HistoryMetric.temperature ? 1 : 0)} $_metricUnit',
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ))
              .toList(),
        ),
      ),
    );
  }

  double? _getBottomInterval(double maxX) {
    switch (_selectedRange) {
      case TimeRange.day:
        return 4;
      case TimeRange.week:
        return 1;
      case TimeRange.month:
        return 5;
    }
  }

  String _getBottomTitleText(double val, bool isReal) {
    if (isReal) return '${val.toStringAsFixed(0)}m';

    int v = val.toInt();
    switch (_selectedRange) {
      case TimeRange.day:
        return _formatHourShort(v);
      case TimeRange.week:
        const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        return days[v % 7];
      case TimeRange.month:
        return '${v + 1}';
    }
  }

  (double, double) _getYRange() {
    switch (_selectedMetric) {
      case HistoryMetric.stress:
        return (0, 100);
      case HistoryMetric.heartRate:
        return (50, 160);
      case HistoryMetric.hrv:
        return (0, 80);
      case HistoryMetric.activity:
        return (0, 100);
      case HistoryMetric.temperature:
        return (34, 40);
    }
  }

  // ── Grid Builder ───────────────────────────────────────────────────────────

  Widget _buildCompactGrid(List<FlSpot> spots, bool isReal) {
    if (isReal) {
      final history = _ble.history.reversed.toList();
      final displayCount = _isExpanded ? history.length : min(6, history.length);
      
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 68,
        ),
        itemCount: displayCount,
        itemBuilder: (context, index) => _ReadingTile(
          data: history[index],
          metric: _selectedMetric,
        ),
      );
    } else {
      final displaySpots = _isExpanded ? spots.reversed.toList() : spots.reversed.take(6).toList();
      
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 48,
        ),
        itemCount: displaySpots.length,
        itemBuilder: (context, index) => _AggregatedTile(
          spot: displaySpots[index],
          metric: _selectedMetric,
          range: _selectedRange,
        ),
      );
    }
  }

  // ── Data Mappers ───────────────────────────────────────────────────────────

  String _getMetricLabelFor(HistoryMetric m) {
    switch (m) {
      case HistoryMetric.stress:
        return 'Stres';
      case HistoryMetric.heartRate:
        return 'Jantung';
      case HistoryMetric.hrv:
        return 'HRV';
      case HistoryMetric.activity:
        return 'Gerak';
      case HistoryMetric.temperature:
        return 'Suhu';
    }
  }

  Color _getMetricColorFor(HistoryMetric m) {
    switch (m) {
      case HistoryMetric.stress:
        return const Color(0xFF6C63FF);
      case HistoryMetric.heartRate:
        return const Color(0xFFF44336);
      case HistoryMetric.hrv:
        return const Color(0xFF7C4DFF);
      case HistoryMetric.activity:
        return const Color(0xFF4CAF50);
      case HistoryMetric.temperature:
        return const Color(0xFFFF9800);
    }
  }

  String _formatHourShort(int h) {
    int hour = h % 24;
    if (hour == 0) return '12am';
    if (hour < 12) return '${hour}am';
    if (hour == 12) return '12pm';
    return '${hour - 12}pm';
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ───────────────────────────────────────────────────────────────────────────

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _CompactStat(
      {required this.label,
      required this.value,
      required this.unit,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  final SensorData data;
  final HistoryMetric metric;
  const _ReadingTile({required this.data, required this.metric});

  @override
  Widget build(BuildContext context) {
    final value = _getValue();
    final unit = _getUnit();
    final color = _getColor();
    final time =
        '${data.timestamp.hour.toString().padLeft(2, '0')}:${data.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(time,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800)),
                Text(_getStatusLabel(),
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.toStringAsFixed(metric == HistoryMetric.temperature ? 1 : 0),
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: color),
              ),
              Text(unit,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }

  double _getValue() {
    switch (metric) {
      case HistoryMetric.stress:
        return data.stressIndex.toDouble();
      case HistoryMetric.heartRate:
        return data.heartRate.toDouble();
      case HistoryMetric.hrv:
        return data.hrv.toDouble();
      case HistoryMetric.activity:
        return data.motionScore.toDouble();
      case HistoryMetric.temperature:
        return data.temperature;
    }
  }

  String _getUnit() {
    switch (metric) {
      case HistoryMetric.stress:
        return '%';
      case HistoryMetric.heartRate:
        return 'BPM';
      case HistoryMetric.hrv:
        return 'ms';
      case HistoryMetric.activity:
        return '/100';
      case HistoryMetric.temperature:
        return '°C';
    }
  }

  Color _getColor() {
    switch (metric) {
      case HistoryMetric.stress:
        return const Color(0xFF6C63FF);
      case HistoryMetric.heartRate:
        return const Color(0xFFF44336);
      case HistoryMetric.hrv:
        return const Color(0xFF7C4DFF);
      case HistoryMetric.activity:
        return const Color(0xFF4CAF50);
      case HistoryMetric.temperature:
        return const Color(0xFFFF9800);
    }
  }

  String _getStatusLabel() {
    switch (metric) {
      case HistoryMetric.stress:
        return data.stressLabelShort;
      case HistoryMetric.heartRate:
        return data.heartRateLabel;
      case HistoryMetric.hrv:
        return data.hrvLabel;
      case HistoryMetric.activity:
        return data.activityLabel;
      case HistoryMetric.temperature:
        return data.temperatureLabel;
    }
  }
}

class _AggregatedTile extends StatelessWidget {
  final FlSpot spot;
  final HistoryMetric metric;
  final TimeRange range;
  const _AggregatedTile(
      {required this.spot, required this.metric, required this.range});

  @override
  Widget build(BuildContext context) {
    final v = spot.x.toInt();
    final timeStr = _getTimeStr(v);
    final valStr =
        spot.y.toStringAsFixed(metric == HistoryMetric.temperature ? 1 : 0);
    final color = _getColor();
    final unit = _getUnit();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade50)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(timeStr,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          Text('$valStr $unit',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _getTimeStr(int v) {
    switch (range) {
      case TimeRange.day:
        if (v == 0) return '12 AM';
        if (v < 12) return '$v AM';
        if (v == 12) return '12 PM';
        return '${v - 12} PM';
      case TimeRange.week:
        const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        return days[v % 7];
      case TimeRange.month:
        return 'Tgl ${v + 1}';
    }
  }

  String _getUnit() {
    switch (metric) {
      case HistoryMetric.stress:
        return '%';
      case HistoryMetric.heartRate:
        return 'BPM';
      case HistoryMetric.hrv:
        return 'ms';
      case HistoryMetric.activity:
        return '/100';
      case HistoryMetric.temperature:
        return '°C';
    }
  }

  Color _getColor() {
    switch (metric) {
      case HistoryMetric.stress:
        return const Color(0xFF6C63FF);
      case HistoryMetric.heartRate:
        return const Color(0xFFF44336);
      case HistoryMetric.hrv:
        return const Color(0xFF7C4DFF);
      case HistoryMetric.activity:
        return const Color(0xFF4CAF50);
      case HistoryMetric.temperature:
        return const Color(0xFFFF9800);
    }
  }
}
