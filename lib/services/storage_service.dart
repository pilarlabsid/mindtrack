import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Manages local storage for user profile and app settings.
///
/// Uses SharedPreferences for lightweight key-value persistence.
class StorageService {
  static const _keyName = 'user_name';
  static const _keyAge = 'user_age';
  static const _keyDeviceName = 'last_device_name';
  static const _keyDeviceId = 'last_device_id';
  static const _keyOnboarded = 'onboarded';

  /// Check if the user has completed onboarding.
  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarded) ?? false;
  }

  /// Mark onboarding as complete.
  Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, true);
  }

  /// Save user profile to local storage.
  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, profile.name);
    
    if (profile.age != null) {
      await prefs.setInt(_keyAge, profile.age!);
    } else {
      await prefs.remove(_keyAge);
    }
    
    if (profile.lastDeviceName != null) {
      await prefs.setString(_keyDeviceName, profile.lastDeviceName!);
    }
    if (profile.lastDeviceId != null) {
      await prefs.setString(_keyDeviceId, profile.lastDeviceId!);
    }
  }

  /// Load user profile from local storage.
  Future<UserProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName);
    if (name == null) return null;
    
    return UserProfile(
      name: name,
      age: prefs.getInt(_keyAge),
      lastDeviceName: prefs.getString(_keyDeviceName),
      lastDeviceId: prefs.getString(_keyDeviceId),
    );
  }

  /// Save the last connected device info for auto-reconnect.
  Future<void> saveLastDevice(String name, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceName, name);
    await prefs.setString(_keyDeviceId, id);
  }
}
