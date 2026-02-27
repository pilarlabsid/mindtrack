import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'models/sensor_data.dart';
import 'services/ble_service.dart';
import 'services/storage_service.dart';
import 'screens/scan_screen.dart';
import 'widgets/info_card.dart';
import 'widgets/stress_indicator.dart';

/// Dashboard screen – main view showing live sensor readings.
///
/// When a BLE device is connected, data comes from the ESP32.
/// When disconnected, simulated mock data is generated every 2 seconds.
class DashboardScreen extends StatefulWidget {
  final BleService bleService;
  const DashboardScreen({super.key, required this.bleService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  final _storage = StorageService();

  late SensorData _current;
  String _userName = 'User';

  // Timer for mock data when BLE is not connected
  Timer? _mockTimer;

  // Animation controller for the stress indicator pulse
  late AnimationController _pulseController;

  // BLE data subscription
  StreamSubscription<SensorData>? _bleSub;

  BleService get _ble => widget.bleService;

  @override
  void initState() {
    super.initState();
    _current = _generateReading();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Load user name from storage
    _loadProfile();

    // Listen to BLE service changes (connected / disconnected)
    _ble.addListener(_onBleStateChanged);

    // Listen to BLE data stream
    _bleSub = _ble.dataStream.listen((data) {
      if (mounted) setState(() => _current = data);
    });

    // Start mock data if not connected
    _updateDataSource();
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _bleSub?.cancel();
    _pulseController.dispose();
    _ble.removeListener(_onBleStateChanged);
    super.dispose();
  }

  void _onBleStateChanged() {
    _updateDataSource();
    if (mounted) setState(() {});
  }

  /// Start mock timer when disconnected, stop it when connected.
  void _updateDataSource() {
    if (_ble.isConnected) {
      // Stop mock data — real data comes from BLE
      _mockTimer?.cancel();
      _mockTimer = null;
    } else {
      // Start mock data generation
      _mockTimer ??= Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) setState(() => _current = _generateReading());
      });
    }
  }

  Future<void> _loadProfile() async {
    final profile = await _storage.loadProfile();
    if (profile != null && mounted) {
      setState(() => _userName = profile.name);
    }
  }

  SensorData _generateReading() {
    final movements = ['Low', 'Medium', 'High'];
    return SensorData(
      heartRate: _rng.nextInt(51) + 60,
      temperature: 36.0 + _rng.nextDouble() * 1.5,
      movement: movements[_rng.nextInt(3)],
      stressIndex: _rng.nextInt(81) + 10,
      timestamp: DateTime.now(),
    );
  }

  Color get _stressColor {
    if (_current.stressIndex <= 30) return const Color(0xFF4CAF50);
    if (_current.stressIndex <= 60) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  void _openScanScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanScreen(bleService: _ble),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (!_ble.isConnected) {
              setState(() => _current = _generateReading());
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── App Bar ─────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xFFF8F9FE),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $_userName 👋',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      'MindTrack – Stress Monitor',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Connection button that opens BLE scan
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: _openScanScreen,
                      child: _ConnectionBadge(
                        isConnected: _ble.isConnected,
                        deviceName: _ble.connectedDeviceName,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Body ────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Data source indicator
                    if (!_ble.isConnected)
                      _MockDataBanner(onConnect: _openScanScreen),

                    // Stress indicator
                    StressIndicator(
                      stressLevel: _current.stressIndex,
                      label: _current.stressLabel,
                      color: _stressColor,
                      pulseController: _pulseController,
                    ),
                    const SizedBox(height: 28),

                    // Section label
                    Text(
                      'Physiological Data',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2×2 grid of info cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.05,
                      children: [
                        InfoCard(
                          icon: Icons.favorite_rounded,
                          iconColor: const Color(0xFFF44336),
                          label: 'Heart Rate',
                          value: '${_current.heartRate} BPM',
                        ),
                        InfoCard(
                          icon: Icons.device_thermostat_rounded,
                          iconColor: const Color(0xFFFF9800),
                          label: 'Skin Temp',
                          value:
                              '${_current.temperature.toStringAsFixed(1)} °C',
                        ),
                        InfoCard(
                          icon: Icons.directions_run_rounded,
                          iconColor: const Color(0xFF4CAF50),
                          label: 'Movement',
                          value: _current.movement,
                        ),
                        InfoCard(
                          icon: Icons.psychology_rounded,
                          iconColor: const Color(0xFF6C63FF),
                          label: 'Stress Index',
                          value: '${_current.stressIndex}%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Last updated timestamp
                    Center(
                      child: Text(
                        'Last updated: ${_formatTime(_current.timestamp)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
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

/// Shows device connectivity status. Tapping opens the scan screen.
class _ConnectionBadge extends StatelessWidget {
  final bool isConnected;
  final String? deviceName;
  const _ConnectionBadge({required this.isConnected, this.deviceName});

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? const Color(0xFF4CAF50) : Colors.grey.shade400;
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
            isConnected ? (deviceName ?? 'Connected') : 'No Device',
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
              'Showing simulated data. Connect your device for real readings.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onConnect,
            child: const Text(
              'Connect',
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
