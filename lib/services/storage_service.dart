import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/user_profile.dart';

/// Manages local storage for user profile and app settings.
///
/// Uses SharedPreferences for lightweight key-value persistence.
class StorageService {
  static const _keyUid = 'user_uid';
  static const _keyName = 'user_name';
  static const _keyBirthDate = 'user_birthdate'; // Key for DateTime
  static const _keyHeight = 'user_height';
  static const _keyWeight = 'user_weight';
  static const _keyPhoto = 'user_photo';
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
    
    if (profile.uid != null) {
      await prefs.setString(_keyUid, profile.uid!);
    }
    
    await prefs.setString(_keyName, profile.name);
    
    if (profile.birthDate != null) {
      await prefs.setString(_keyBirthDate, profile.birthDate!.toIso8601String());
    } else {
      await prefs.remove(_keyBirthDate);
    }

    if (profile.height != null) {
      await prefs.setDouble(_keyHeight, profile.height!);
    } else {
      await prefs.remove(_keyHeight);
    }

    if (profile.weight != null) {
      await prefs.setDouble(_keyWeight, profile.weight!);
    } else {
      await prefs.remove(_keyWeight);
    }

    if (profile.photoPath != null) {
      await prefs.setString(_keyPhoto, profile.photoPath!);
    } else {
      await prefs.remove(_keyPhoto);
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
    
    String? uid = prefs.getString(_keyUid);
    if (uid == null) {
      uid = _generateShortId();
      await prefs.setString(_keyUid, uid);
    }

    if (name == null) {
      return UserProfile(uid: uid, name: 'User Baru');
    }

    final birthDateStr = prefs.getString(_keyBirthDate);
    DateTime? birthDate;
    if (birthDateStr != null) {
      birthDate = DateTime.tryParse(birthDateStr);
    }
    
    return UserProfile(
      uid: uid,
      name: name,
      birthDate: birthDate,
      height: prefs.getDouble(_keyHeight),
      weight: prefs.getDouble(_keyWeight),
      photoPath: prefs.getString(_keyPhoto),
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

  String _generateShortId() {
    final rand = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (index) => chars[rand.nextInt(chars.length)]).join();
  }
}
