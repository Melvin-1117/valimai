import 'dart:io';

import 'package:flutter/foundation.dart';

import 'web_storage.dart';

/// Centralized utility for resolving writable local storage across Web, Windows, Android, iOS, and Linux.
class StorageHelper {
  static Directory? _cachedDirectory;
  static const String _cleanV1Flag = 'valimai_fresh_v1.flag';
  static final Map<String, String> _webMemoryStore = <String, String>{};

  /// Allows tests or sandbox runners to inject an isolated temporary directory.
  @visibleForTesting
  static void setStorageDirectory(Directory? dir) {
    _cachedDirectory = dir;
  }

  /// Resolves a writable directory across all native platforms.
  static Future<Directory> getStorageDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Filesystem directories are not supported on Flutter Web. Use StorageHelper.safeReadString/safeWriteString.',
      );
    }

    if (_cachedDirectory != null) {
      return _cachedDirectory!;
    }

    // 1. Windows: Try LOCALAPPDATA or APPDATA
    try {
      final localAppData =
          Platform.environment['LOCALAPPDATA'] ??
          Platform.environment['APPDATA'];
      if (localAppData != null && localAppData.isNotEmpty) {
        final dir = Directory('$localAppData/Valimai');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        _cachedDirectory = dir;
        return dir;
      }
    } catch (_) {}

    // 2. Mobile / Unix: Try System Temp directory (always writable in mobile sandboxes)
    try {
      final tempDir = Directory('${Directory.systemTemp.path}/valimai_data');
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      _cachedDirectory = tempDir;
      return tempDir;
    } catch (_) {}

    // 3. Fallback to application relative folder
    try {
      final dir = Directory('.valimai_data');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _cachedDirectory = dir;
      return dir;
    } catch (_) {}

    _cachedDirectory = Directory.current;
    return Directory.current;
  }

  /// Get file handle with platform-independent forward slashes (native only)
  static Future<File> getStorageFile(String fileName) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'File system handles are not supported on Flutter Web. Use StorageHelper.safeReadString/safeWriteString.',
      );
    }
    final dir = await getStorageDirectory();
    return File('${dir.path}/$fileName');
  }

  /// Safe write string with atomic staging (.tmp file) and buffer flushing on native,
  /// and persistent localStorage + memory store on Flutter Web.
  static Future<bool> safeWriteString(String fileName, String content) async {
    if (kIsWeb) {
      _webMemoryStore[fileName] = content;
      WebStorageBridge.setItem(fileName, content);
      return true;
    }

    try {
      final file = await getStorageFile(fileName);
      final tempFile = File('${file.path}.tmp');
      await tempFile.writeAsString(content, flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await tempFile.rename(file.path);
      return true;
    } catch (e) {
      debugPrint('Primary atomic write failed for $fileName: $e');
      // Direct write fallback to primary location
      try {
        final file = await getStorageFile(fileName);
        await file.writeAsString(content, flush: true);
        return true;
      } catch (directError) {
        debugPrint('Primary direct write failed for $fileName: $directError');
        // Secondary fallback to system temp directory
        try {
          final fallbackDir = Directory(
            '${Directory.systemTemp.path}/valimai_data',
          );
          if (!await fallbackDir.exists()) {
            await fallbackDir.create(recursive: true);
          }
          final fallbackFile = File('${fallbackDir.path}/$fileName');
          await fallbackFile.writeAsString(content, flush: true);
          return true;
        } catch (fallbackError) {
          debugPrint('Fallback write failed for $fileName: $fallbackError');
          return false;
        }
      }
    }
  }

  /// Safe read string from primary or fallback location on native,
  /// or from localStorage/memory on Flutter Web.
  static Future<String?> safeReadString(String fileName) async {
    if (kIsWeb) {
      if (_webMemoryStore.containsKey(fileName)) {
        return _webMemoryStore[fileName];
      }
      final persisted = WebStorageBridge.getItem(fileName);
      if (persisted != null && persisted.trim().isNotEmpty) {
        _webMemoryStore[fileName] = persisted;
        return persisted;
      }
      return null;
    }

    try {
      final file = await getStorageFile(fileName);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) return content;
      }
    } catch (_) {}

    try {
      final fallbackFile = File(
        '${Directory.systemTemp.path}/valimai_data/$fileName',
      );
      if (await fallbackFile.exists()) {
        final content = await fallbackFile.readAsString();
        if (content.trim().isNotEmpty) return content;
      }
    } catch (_) {}

    return null;
  }

  /// Safe delete file from primary and fallback storage directories on native,
  /// or from localStorage/memory on Flutter Web.
  static Future<bool> safeDeleteFile(String fileName) async {
    if (kIsWeb) {
      _webMemoryStore.remove(fileName);
      WebStorageBridge.removeItem(fileName);
      return true;
    }

    bool deleted = false;
    try {
      final file = await getStorageFile(fileName);
      if (await file.exists()) {
        await file.delete();
        deleted = true;
      }
    } catch (_) {}

    try {
      final fallbackFile = File(
        '${Directory.systemTemp.path}/valimai_data/$fileName',
      );
      if (await fallbackFile.exists()) {
        await fallbackFile.delete();
        deleted = true;
      }
    } catch (_) {}

    return deleted;
  }

  /// Performs a controlled one-time cleanup of development/mock data files.
  /// Once run, writes a persistent sentinel flag so it never runs again,
  /// strictly preserving legitimate user records going forward.
  static Future<void> cleanDevMockDataOnce() async {
    try {
      if (kIsWeb) {
        final flag = await safeReadString(_cleanV1Flag);
        if (flag != null && flag.isNotEmpty) {
          return; // Already cleaned, do not touch user data!
        }

        const devFilesToRemove = [
          'valimai_schedule.json',
          'valimai_weekly_plan.json',
          'valimai_routines.json',
          'valimai_workouts.json',
          'valimai_history.json',
          'valimai_daily_workouts.json',
        ];

        for (final fileName in devFilesToRemove) {
          await safeDeleteFile(fileName);
        }

        await safeWriteString(_cleanV1Flag, DateTime.now().toIso8601String());
        return;
      }

      final flagFile = await getStorageFile(_cleanV1Flag);
      if (await flagFile.exists()) {
        return; // Already cleaned, do not touch user data!
      }

      final fallbackFile = File(
        '${Directory.systemTemp.path}/valimai_data/$_cleanV1Flag',
      );
      if (await fallbackFile.exists()) {
        return;
      }

      // Remove previously generated development / mock data files
      const devFilesToRemove = [
        'valimai_schedule.json',
        'valimai_weekly_plan.json',
        'valimai_routines.json',
        'valimai_workouts.json',
        'valimai_history.json',
        'valimai_daily_workouts.json',
      ];

      for (final fileName in devFilesToRemove) {
        await safeDeleteFile(fileName);
      }

      // Write sentinel flag so cleanup runs only once
      await safeWriteString(_cleanV1Flag, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('cleanDevMockDataOnce error: $e');
    }
  }
}
