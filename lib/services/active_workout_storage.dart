import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/active_workout_session.dart';
import 'storage_helper.dart';

/// Contract for active workout session persistence
abstract class IActiveWorkoutStorage {
  Future<ActiveWorkoutSession?> loadActiveSession();
  Future<bool> saveActiveSession(ActiveWorkoutSession session);
  Future<bool> clearActiveSession();
}

/// Offline-first atomic storage implementation for active workout sessions
class LocalActiveWorkoutStorage implements IActiveWorkoutStorage {
  static const String _fileName = 'valimai_active_session.json';

  @override
  Future<ActiveWorkoutSession?> loadActiveSession() async {
    try {
      final jsonStr = await StorageHelper.safeReadString(_fileName);
      if (jsonStr == null || jsonStr.trim().isEmpty) return null;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final session = ActiveWorkoutSession.fromJson(map);
      // Strictly ignore sessions that were already marked completed or discarded
      if (!session.isActive) return null;
      return session;
    } catch (e) {
      debugPrint('LocalActiveWorkoutStorage.loadActiveSession error: $e');
      return null;
    }
  }

  @override
  Future<bool> saveActiveSession(ActiveWorkoutSession session) async {
    try {
      final jsonStr = jsonEncode(session.toJson());
      return await StorageHelper.safeWriteString(_fileName, jsonStr);
    } catch (e) {
      debugPrint('LocalActiveWorkoutStorage.saveActiveSession error: $e');
      return false;
    }
  }

  @override
  Future<bool> clearActiveSession() async {
    try {
      return await StorageHelper.safeDeleteFile(_fileName);
    } catch (e) {
      debugPrint('LocalActiveWorkoutStorage.clearActiveSession error: $e');
      return false;
    }
  }
}

/// In-memory mock storage for testing active workout sessions
class MockActiveWorkoutStorage implements IActiveWorkoutStorage {
  ActiveWorkoutSession? _memorySession;

  @override
  Future<ActiveWorkoutSession?> loadActiveSession() async {
    if (_memorySession != null && !_memorySession!.isActive) {
      return null;
    }
    return _memorySession;
  }

  @override
  Future<bool> saveActiveSession(ActiveWorkoutSession session) async {
    _memorySession = session;
    return true;
  }

  @override
  Future<bool> clearActiveSession() async {
    _memorySession = null;
    return true;
  }
}

