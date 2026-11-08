import 'dart:convert';
import 'dart:io';
import '../models/user_profile.dart';
import 'storage_helper.dart';

abstract class IProfileStorage {
  Future<UserProfile?> loadProfile();
  Future<void> saveProfile(UserProfile profile);
  Future<void> clearProfile();
}

class LocalProfileStorage implements IProfileStorage {
  static const String _fileName = 'valimai_profile.json';
  UserProfile? _cachedProfile;

  @override
  Future<UserProfile?> loadProfile() async {
    // Check in-memory cache first
    if (_cachedProfile != null) {
      return _cachedProfile;
    }

    try {
      final content = await StorageHelper.safeReadString(_fileName);
      if (content != null && content.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(content);
        _cachedProfile = UserProfile.fromJson(data);
        return _cachedProfile;
      }
    } catch (e) {
      // Graceful fallback if storage read encounters I/O issues
    }

    return _cachedProfile;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _cachedProfile = profile;
    try {
      final jsonStr = jsonEncode(profile.toJson());
      await StorageHelper.safeWriteString(_fileName, jsonStr);
    } catch (e) {
      // Cache remains valid in memory
    }
  }

  @override
  Future<void> clearProfile() async {
    _cachedProfile = null;
    try {
      final file = await StorageHelper.getStorageFile(_fileName);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore deletion errors
    }
  }
}

