import 'dart:convert';
import 'dart:io';
import '../models/user_profile.dart';

abstract class IProfileStorage {
  Future<UserProfile?> loadProfile();
  Future<void> saveProfile(UserProfile profile);
  Future<void> clearProfile();
}

class LocalProfileStorage implements IProfileStorage {
  static const String _fileName = 'valimai_profile.json';
  UserProfile? _cachedProfile;

  File? _resolvedFile;

  Future<File> _getFile() async {
    if (_resolvedFile != null) return _resolvedFile!;

    Directory baseDir;
    try {
      // 1. Try Windows LOCALAPPDATA / APPDATA if available
      final localAppData = Platform.environment['LOCALAPPDATA'] ??
          Platform.environment['APPDATA'];
      if (localAppData != null && localAppData.isNotEmpty) {
        baseDir = Directory('$localAppData/Valimai');
        if (!await baseDir.exists()) {
          await baseDir.create(recursive: true);
        }
      } else {
        // 2. Try current application directory
        baseDir = Directory('.valimai_data');
        if (!await baseDir.exists()) {
          await baseDir.create(recursive: true);
        }
      }
    } catch (_) {
      // 3. Fallback to system temp directory
      try {
        baseDir = Directory('${Directory.systemTemp.path}/valimai_data');
        if (!await baseDir.exists()) {
          await baseDir.create(recursive: true);
        }
      } catch (_) {
        baseDir = Directory.current;
      }
    }

    _resolvedFile = File('${baseDir.path}/$_fileName');
    return _resolvedFile!;
  }

  @override
  Future<UserProfile?> loadProfile() async {
    // Check in-memory cache first
    if (_cachedProfile != null) {
      return _cachedProfile;
    }

    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          _cachedProfile = UserProfile.fromJson(data);
          return _cachedProfile;
        }
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
      final file = await _getFile();
      final jsonStr = jsonEncode(profile.toJson());
      await file.writeAsString(jsonStr, flush: true);
    } catch (e) {
      // Log / cache remains valid in memory
    }
  }

  @override
  Future<void> clearProfile() async {
    _cachedProfile = null;
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore deletion errors
    }
  }
}

