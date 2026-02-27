/// Simple user profile stored locally on the device.
class UserProfile {
  final String name;
  final int? age;                // User age for better heart rate stress baseline
  final String? lastDeviceName;  // Name of last paired ESP32
  final String? lastDeviceId;    // MAC / remoteId of last paired device

  const UserProfile({
    required this.name,
    this.age,
    this.lastDeviceName,
    this.lastDeviceId,
  });

  UserProfile copyWith({
    String? name,
    int? age,
    String? lastDeviceName,
    String? lastDeviceId,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      lastDeviceName: lastDeviceName ?? this.lastDeviceName,
      lastDeviceId: lastDeviceId ?? this.lastDeviceId,
    );
  }
}
