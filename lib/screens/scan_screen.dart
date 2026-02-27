import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';

/// Screen that scans for BLE devices and lets the user connect to one.
class ScanScreen extends StatefulWidget {
  final BleService bleService;
  const ScanScreen({super.key, required this.bleService});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _storage = StorageService();
  bool _connecting = false;
  String? _connectingId;

  BleService get _ble => widget.bleService;

  @override
  void initState() {
    super.initState();
    _ble.addListener(_refresh);
    // Start scanning immediately when screen opens
    _startScan();
  }

  @override
  void dispose() {
    _ble.removeListener(_refresh);
    _ble.stopScan();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _startScan() async {
    await _ble.startScan(timeout: const Duration(seconds: 12));
  }

  Future<void> _connect(ScanResult result) async {
    setState(() {
      _connecting = true;
      _connectingId = result.device.remoteId.str;
    });

    final success = await _ble.connectToDevice(result.device);

    if (success) {
      // Save this device for quick reconnect later
      await _storage.saveLastDevice(
        result.device.platformName,
        result.device.remoteId.str,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${result.device.platformName}'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Could not connect. Make sure the device is a MindTrack device.'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _connecting = false;
        _connectingId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        title: const Text(
          'Connect Device',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
        ),
        actions: [
          if (_ble.isScanning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6C63FF),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6C63FF)),
              onPressed: _startScan,
              tooltip: 'Scan again',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status banner ────────────────────────────────────────
            if (_ble.isConnected)
              _buildConnectedBanner()
            else
              _buildScanHint(),

            const SizedBox(height: 8),

            // ── Device list ──────────────────────────────────────────
            Expanded(
              child: _ble.scanResults.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _ble.scanResults.length,
                      itemBuilder: (ctx, i) =>
                          _buildDeviceTile(_ble.scanResults[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────

  Widget _buildConnectedBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_connected, color: Color(0xFF4CAF50)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ble.connectedDeviceName ?? 'Device',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  'Connected · ${_ble.connectedDeviceId ?? ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await _ble.disconnect();
              _startScan();
            },
            child: const Text('Disconnect',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildScanHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Text(
        _ble.isScanning
            ? 'Searching for nearby devices...'
            : 'Tap a device below to connect, or press refresh to scan again.',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bluetooth_searching_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _ble.isScanning ? 'Scanning...' : 'No devices found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure your ESP32 device is powered on\nand in Bluetooth range.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          if (!_ble.isScanning)
            OutlinedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scan Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
                side: const BorderSide(color: Color(0xFF6C63FF)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(ScanResult result) {
    final device = result.device;
    final rssi = result.rssi;
    final isConnecting = _connectingId == device.remoteId.str;

    // RSSI → signal strength indicator
    IconData signalIcon;
    Color signalColor;
    if (rssi >= -60) {
      signalIcon = Icons.signal_cellular_alt;
      signalColor = const Color(0xFF4CAF50);
    } else if (rssi >= -80) {
      signalIcon = Icons.signal_cellular_alt_2_bar;
      signalColor = const Color(0xFFFF9800);
    } else {
      signalIcon = Icons.signal_cellular_alt_1_bar;
      signalColor = const Color(0xFFF44336);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bluetooth_rounded, color: Color(0xFF6C63FF)),
        ),
        title: Text(
          device.platformName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              device.remoteId.str,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 8),
            Icon(signalIcon, size: 14, color: signalColor),
            Text(
              ' $rssi dBm',
              style: TextStyle(fontSize: 11, color: signalColor),
            ),
          ],
        ),
        trailing: isConnecting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF6C63FF),
                ),
              )
            : const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Color(0xFF6C63FF)),
        onTap: (_connecting || _ble.isConnected) ? null : () => _connect(result),
      ),
    );
  }
}
