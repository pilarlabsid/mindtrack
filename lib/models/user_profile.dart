/// Simple user profile stored locally on the device.
class UserProfile {
  final String name;
  final String? lastDeviceName;  // Name of last paired ESP32
  final String? lastDeviceId;    // MAC / remoteId of last paired device

  const UserProfile({
    required this.name,
    this.lastDeviceName,
    this.lastDeviceId,
  });

  UserProfile copyWith({
    String? name,
    String? lastDeviceName,
    String? lastDeviceId,
  }) {
    return UserProfile(
      name: name ?? this.name,
      lastDeviceName: lastDeviceName ?? this.lastDeviceName,
      lastDeviceId: lastDeviceId ?? this.lastDeviceId,
    );
  }
}
