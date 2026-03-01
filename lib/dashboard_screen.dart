import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'models/sensor_data.dart';
import 'services/ble_service.dart';
import 'services/storage_service.dart';
import 'screens/profile_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/sensor_detail_screen.dart';
import 'screens/stress_edu_screen.dart';
import 'package:flutter/services.dart';
import 'widgets/stress_indicator.dart';
import 'widgets/app_watermark.dart';

/// Dashboard screen – main view showing live sensor readings in a
/// friendly, user-facing layout.
///
/// When a BLE device is connected, data comes from the ESP32.
/// When disconnected, simulated mock data is generated every 2 seconds.
class DashboardScreen extends StatefulWidget {
  final BleService bleService;
  const DashboardScreen({super.key, required this.bleService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _rng = Random();
  final _storage = StorageService();

  late SensorData _current;
  String _userName = 'User';
  String? _photoPath;
  int? _userAge;
  double? _userHeight;
  double? _userWeight;

  Timer? _mockTimer;
  StreamSubscription<SensorData>? _bleSub;

  BleService get _ble => widget.bleService;

  @override
  void initState() {
    super.initState();
    _current = _generateReading();
    _loadProfile();
    _ble.addListener(_onBleStateChanged);
    _bleSub = _ble.dataStream.listen((data) {
      if (mounted) setState(() => _current = data);
    });
    _updateDataSource();
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _bleSub?.cancel();
    _ble.removeListener(_onBleStateChanged);
    super.dispose();
  }

  void _onBleStateChanged() {
    _updateDataSource();
    if (mounted) setState(() {});
  }

  void _updateDataSource() {
    if (_ble.isConnected) {
      _mockTimer?.cancel();
      _mockTimer = null;
    } else {
      _mockTimer ??= Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) setState(() => _current = _generateReading());
      });
    }
  }

  Future<void> _loadProfile() async {
    final profile = await _storage.loadProfile();
    if (profile != null && mounted) {
      setState(() {
        _userName = profile.name;
        _photoPath = profile.photoPath;
        _userAge = profile.age;
        _userHeight = profile.height;
        _userWeight = profile.weight;
      });
    }
  }

  SensorData _generateReading() {
    final hr = _rng.nextInt(51) + 60;   // 60–110
    final ibi = hr > 0 ? (60000 ~/ hr) : 700; // approximate IBI from HR
    return SensorData(
      heartRate:   hr,
      ibi:         ibi + _rng.nextInt(60) - 30,
      hrv:         _rng.nextInt(35) + 8,         // 8–43 ms
      temperature: 36.0 + _rng.nextDouble() * 1.5,
      motionScore: _rng.nextInt(61),              // 0–60, mostly low
      stressIndex: _rng.nextInt(81) + 10,
      gsrPercent:  _rng.nextInt(81) + 10,        // 10–90%
      irRaw:       _rng.nextInt(50000) + 100000,
      accelX:      (_rng.nextDouble() - 0.5) * 0.4,
      accelY:      (_rng.nextDouble() - 0.5) * 0.4,
      accelZ:      9.7 + _rng.nextDouble() * 0.2,
      timestamp:   DateTime.now(),
    );
  }

  Color get _stressColor {
    final idx = _current.getAdjustedStress(_userAge, _userHeight, _userWeight);
    if (idx <= 30) return const Color(0xFF10B981); // Green
    if (idx <= 60) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  void _openScanScreen() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScanScreen(bleService: _ble)),
    );
  }

  Future<void> _openProfileScreen() async {
    HapticFeedback.selectionClick();
    final updated = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    if (updated == true) _loadProfile();
  }

  void _openSensorDetail() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => SensorDetailScreen(bleService: _ble)),
    );
  }

  void _openStressEdu() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StressEduScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6C63FF),
          onRefresh: () async {
            HapticFeedback.lightImpact();
            if (!_ble.isConnected) {
              setState(() => _current = _generateReading());
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── App Bar ────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFFF2F4F8),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _openProfileScreen,
                      child: Text(
                        'Hai, $_userName',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    Text(
                      'MindTrack – Pemantau Kesehatan & Stres',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _openScanScreen,
                          child: _ConnectionBadge(
                            isConnected: _ble.isConnected,
                            deviceName: _ble.connectedDeviceName,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _openProfileScreen,
                          child: CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              const Color(0xFF5C55ED).withValues(alpha: 0.1),
                          backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                          child: _photoPath == null 
                              ? const Icon(Icons.person, size: 20, color: Color(0xFF5C55ED))
                              : null,
                        ),  ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Body ───────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // Mock banner
                    if (!_ble.isConnected)
                      _MockDataBanner(onConnect: _openScanScreen),

                    // Stress Insights Entry
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kondisi Stres Anda',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _openStressEdu,
                          icon: const Icon(Icons.info_outline_rounded, size: 14),
                          label: const Text('Wawasan Stres', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Stress Hero
                    StressIndicator(
                      stressLevel: _current.getAdjustedStress(_userAge, _userHeight, _userWeight),
                      label: _current.getStressLabel(_userAge, _userHeight, _userWeight),
                      color: _stressColor,
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Stress Insight Card
                    _StressInsightCard(
                      analysis: _current.getStressAnalysis(_userAge, _userHeight, _userWeight),
                      recommendation: _current.getRecommendation(_userAge, _userHeight, _userWeight),
                      accentColor: _stressColor,
                    ),
                    const SizedBox(height: 24),

                    // ══════════════════════════════════════════════════════
                    // SECTION 1 – Kondisi Jantung & Tubuh
                    // ══════════════════════════════════════════════════════
                    _SectionHeader(
                      icon: Icons.favorite_rounded,
                      title: 'Jantung & Tubuh',
                      subtitle: 'Dipantau langsung dari perangkat',
                      accentColor: const Color(0xFFF44336),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                      children: [
                        _HealthCard(
                          icon: Icons.favorite_rounded,
                          label: 'Detak Jantung',
                          value: _current.heartRate.toDouble(),
                          maxValue: 200,
                          displayText: '${_current.heartRate}',
                          unit: 'BPM',
                          sublabel: _current.heartRateLabel,
                          barColor: const Color(0xFFF44336),
                        ),
                        _HealthCard(
                          icon: Icons.device_thermostat_rounded,
                          label: 'Suhu Tubuh',
                          value: (_current.temperature - 34.0).clamp(0.0, 8.0),
                          maxValue: 8.0,
                          displayText:
                              _current.temperature.toStringAsFixed(1),
                          unit: '°C',
                          sublabel: _current.temperatureLabel,
                          barColor: const Color(0xFFFF9800),
                        ),
                        _HealthCard(
                          icon: Icons.timeline_rounded,
                          label: 'HRV (Variabilitas)',
                          value: _current.hrv.toDouble(),
                          maxValue: 60,
                          displayText: '${_current.hrv}',
                          unit: 'ms',
                          sublabel: _current.hrvLabel,
                          barColor: const Color(0xFF7C4DFF),
                        ),
                        _HealthCard(
                          icon: Icons.directions_run_rounded,
                          label: 'Tingkat Aktivitas',
                          value: _current.motionScore.toDouble(),
                          maxValue: 100,
                          displayText: '${_current.motionScore}',
                          unit: '/100',
                          sublabel: _current.activityLabel,
                          barColor: const Color(0xFF4CAF50),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ══════════════════════════════════════════════════════
                    // SECTION 2 – Kondisi Stres & Kulit
                    // ══════════════════════════════════════════════════════
                    _SectionHeader(
                      icon: Icons.psychology_rounded,
                      title: 'Kondisi Stres & Kulit',
                      subtitle: 'Sensor kulit & indeks stres gabungan',
                      accentColor: const Color(0xFF6C63FF),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                      children: [
                        _HealthCard(
                          icon: Icons.psychology_rounded,
                          label: 'Indeks Stres',
                          value: _current.getAdjustedStress(_userAge, _userHeight, _userWeight).toDouble(),
                          maxValue: 100,
                          displayText: '${_current.getAdjustedStress(_userAge, _userHeight, _userWeight)}',
                          unit: '%',
                          sublabel: _current.getStressLabel(_userAge, _userHeight, _userWeight).replaceAll(RegExp(r'[^\w\s]'), '').trim(),
                          barColor: _stressColor,
                        ),
                        _HealthCard(
                          icon: Icons.water_drop_rounded,
                          label: 'Konduksi Kulit',
                          value: _current.gsrPercent.toDouble(),
                          maxValue: 100,
                          displayText: '${_current.gsrPercent}',
                          unit: '%',
                          sublabel: _current.gsrLabel,
                          barColor: const Color(0xFF00BCD4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Shortcut ke data teknis ────────────────────────────
                    _TechShortcutBanner(onTap: _openSensorDetail),
                    const SizedBox(height: 22),

                    // Last updated
                    Center(
                      child: Text(
                        'Diperbarui ${_formatTime(_current.timestamp)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                      ),
                    ),
                    const AppWatermark(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// =========================================================================
// Sub-widgets
// =========================================================================

// ─────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 38,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: accentColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Health Card (white, with progress bar)
// ─────────────────────────────────────────────
class _HealthCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double maxValue;
  final String displayText;
  final String unit;
  final String sublabel;
  final Color barColor;

  const _HealthCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.displayText,
    required this.unit,
    required this.sublabel,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / maxValue).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: barColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon + status badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: barColor),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Value
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: displayText,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          // Progress bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, p, child) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p,
                backgroundColor: barColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner shortcut menuju halaman data teknis sensor.
class _TechShortcutBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _TechShortcutBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E2A35), Color(0xFF263545)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E2A35).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade700.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.biotech_rounded,
                  size: 18, color: Colors.blueGrey.shade300),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lihat Data Sensor Lengkap',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade100,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'IBI, HRV, GSR, IR, Akselerometer & data teknis',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.blueGrey.shade500, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final bool isConnected;
  final String? deviceName;
  const _ConnectionBadge({required this.isConnected, this.deviceName});

  @override
  Widget build(BuildContext context) {
    final color =
        isConnected ? const Color(0xFF10B981) : Colors.grey.shade400; // Emerald 500
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected
                ? Icons.bluetooth_connected_rounded
                : Icons.bluetooth_disabled_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? (deviceName ?? 'MindTrack Wearable') : 'Tidak Terhubung',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic card providing context and advice based on live stress levels.
class _StressInsightCard extends StatelessWidget {
  final String analysis;
  final String recommendation;
  final Color accentColor;

  const _StressInsightCard({
    required this.analysis,
    required this.recommendation,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: accentColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tips_and_updates_rounded, 
                  color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "Analisis Real-time",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            analysis,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_fix_high_rounded, size: 18, color: Color(0xFF10B981)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Saran Tindakan:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recommendation,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small banner shown when displaying mock data.
class _MockDataBanner extends StatelessWidget {
  final VoidCallback onConnect;
  const _MockDataBanner({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: Color(0xFFFF9800)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Menampilkan data simulasi. Hubungkan perangkat MindTrack untuk data nyata.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onConnect,
            child: const Text(
              'Hubungkan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
