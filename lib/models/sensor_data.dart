/// Holds a single snapshot of sensor readings from the wearable device.
class SensorData {
  final int heartRate;       // BPM
  final double temperature;  // °C
  final String movement;     // Low / Medium / High
  final int stressIndex;     // 0 – 100
  final DateTime timestamp;

  const SensorData({
    required this.heartRate,
    required this.temperature,
    required this.movement,
    required this.stressIndex,
    required this.timestamp,
  });

  /// Derived stress level label based on stress index.
  String get stressLabel {
    if (stressIndex <= 30) return 'Relaxed';
    if (stressIndex <= 60) return 'Normal';
    return 'Stressed';
  }

  /// Create from JSON payload received via BLE.
  /// Expected format: {"hr": 78, "temp": 36.5, "move": 2, "stress": 42, "ts": 1709078400}
  factory SensorData.fromBleJson(Map<String, dynamic> json) {
    // Movement mapping: 0=Low, 1=Medium, 2=High
    const movementLabels = ['Low', 'Medium', 'High'];
    final moveIndex = (json['move'] as int?) ?? 0;

    return SensorData(
      heartRate: (json['hr'] as int?) ?? 0,
      temperature: (json['temp'] as num?)?.toDouble() ?? 0.0,
      movement: movementLabels[moveIndex.clamp(0, 2)],
      stressIndex: ((json['stress'] as int?) ?? 0).clamp(0, 100),
      timestamp: json.containsKey('ts')
          ? DateTime.fromMillisecondsSinceEpoch((json['ts'] as int) * 1000)
          : DateTime.now(),
    );
  }

  /// Convert to Map for local storage.
  Map<String, dynamic> toMap() {
    const movementMap = {'Low': 0, 'Medium': 1, 'High': 2};
    return {
      'hr': heartRate,
      'temp': temperature,
      'move': movementMap[movement] ?? 0,
      'stress': stressIndex,
      'ts': timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }
}
