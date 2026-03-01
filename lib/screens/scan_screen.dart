import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_watermark.dart';

/// Halaman Pencarian Bluetooth – Memungkinkan pengguna mencari dan
/// menghubungkan perangkat MindTrack Wearable.
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
  final Color _primaryColor = const Color(0xFF5C55ED);

  @override
  void initState() {
    super.initState();
    _ble.addListener(_refresh);
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
    HapticFeedback.mediumImpact();
    await _ble.startScan(timeout: const Duration(seconds: 12));
  }

  Future<void> _connect(ScanResult result) async {
    HapticFeedback.selectionClick();
    setState(() {
      _connecting = true;
      _connectingId = result.device.remoteId.str;
    });

    final success = await _ble.connectToDevice(result.device);

    if (success) {
      await _storage.saveLastDevice(
        result.device.platformName,
        result.device.remoteId.str,
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terhubung ke ${result.device.platformName}'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal menghubungkan. Pastikan perangkat aktif dan dalam jangkauan.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hubungkan Perangkat'),
        automaticallyImplyLeading: true,
        actions: [
          if (_ble.isScanning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF5C55ED),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: _primaryColor),
              onPressed: _startScan,
              tooltip: 'Cari lagi',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status Banner ────────────────────────────────────────
            if (_ble.isConnected)
              _buildConnectedBanner()
            else
              _buildScanHint(),

            const SizedBox(height: 12),

            // ── Device List ──────────────────────────────────────────
            Expanded(
              child: _ble.scanResults.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _ble.scanResults.length,
                      itemBuilder: (ctx, i) => _buildDeviceTile(_ble.scanResults[i]),
                    ),
            ),
            
            const AppWatermark(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_connected_rounded, color: Color(0xFF10B981)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ble.connectedDeviceName ?? 'Perangkat',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Sedang Terhubung · ${_ble.connectedDeviceId?.substring(0, 12)}...',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              await _ble.disconnect();
              _startScan();
            },
            child: const Text('Putus', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildScanHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _ble.isScanning ? 'Mencari perangkat terdekat...' : 'Pilih perangkat di bawah untuk menghubungkan.',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            'Pastikan Bluetooth aktif dan perangkat MindTrack dalam jangkauan.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 40, offset: const Offset(0, 10)),
                ],
              ),
              child: Icon(Icons.bluetooth_searching_rounded, size: 64, color: Colors.grey.shade200),
            ),
            const SizedBox(height: 32),
            Text(
              _ble.isScanning ? 'Sedang Mencari...' : 'Perangkat Tidak Ditemukan',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Text(
              'Pastikan MindTrack Wearable Anda menyala dan berada dalam jangkauan Bluetooth HP.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
            const SizedBox(height: 32),
            if (!_ble.isScanning)
              ElevatedButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Cari Ulang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(180, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceTile(ScanResult result) {
    final device = result.device;
    final rssi = result.rssi;
    final isConnecting = _connectingId == device.remoteId.str;

    IconData signalIcon;
    Color signalColor;
    if (rssi >= -60) {
      signalIcon = Icons.signal_cellular_alt_rounded;
      signalColor = const Color(0xFF10B981);
    } else if (rssi >= -80) {
      signalIcon = Icons.signal_cellular_alt_2_bar_rounded;
      signalColor = const Color(0xFFF59E0B);
    } else {
      signalIcon = Icons.signal_cellular_alt_1_bar_rounded;
      signalColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.watch_rounded, color: _primaryColor),
        ),
        title: Text(
          device.platformName.isNotEmpty ? device.platformName : 'MindTrack Wearable',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        subtitle: Row(
          children: [
            Icon(signalIcon, size: 14, color: signalColor),
            const SizedBox(width: 4),
            Text(
              '$rssi dBm',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: signalColor),
            ),
            const SizedBox(width: 8),
            Text(
              device.remoteId.str.substring(0, 12),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
        trailing: isConnecting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: _primaryColor),
              )
            : Icon(Icons.add_circle_outline_rounded, size: 22, color: _primaryColor),
        onTap: (_connecting || _ble.isConnected) ? null : () => _connect(result),
      ),
    );
  }
}
