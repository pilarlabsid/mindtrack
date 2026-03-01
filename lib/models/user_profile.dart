/// Simple user profile stored locally on the device.
class UserProfile {
  final String? uid;             // Unique identifier for the user profile
  final String name;
  final DateTime? birthDate;     // Store birth date for dynamic age calculation
  final double? height;          // User height (cm)
  final double? weight;          // User weight (kg)
  final String? photoPath;       // Local path to profile photo
  final String? lastDeviceName;  // Name of last paired MindTrack Device
  final String? lastDeviceId;    // MAC / remoteId of last paired device

  const UserProfile({
    this.uid,
    required this.name,
    this.birthDate,
    this.height,
    this.weight,
    this.photoPath,
    this.lastDeviceName,
    this.lastDeviceId,
  });

  UserProfile copyWith({
    String? uid,
    String? name,
    DateTime? birthDate,
    double? height,
    double? weight,
    String? photoPath,
    String? lastDeviceName,
    String? lastDeviceId,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      photoPath: photoPath ?? this.photoPath,
      lastDeviceName: lastDeviceName ?? this.lastDeviceName,
      lastDeviceId: lastDeviceId ?? this.lastDeviceId,
    );
  }

  /// Dynamically calculate age based on birthDate and current date.
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
       (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Body Mass Index (BMI) calculation
  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    final hMeter = height! / 100.0;
    return weight! / (hMeter * hMeter);
  }
}
