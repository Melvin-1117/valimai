import 'dart:convert';

import '../models/daily_workout.dart';
import 'storage_helper.dart';

abstract class IDailyWorkoutStorage {
  Future<Map<String, DailyWorkout>> loadDailyWorkouts();
  Future<bool> saveDailyWorkout(DailyWorkout record);
  Future<DailyWorkout?> getDailyWorkoutForDate(String localDate);
}

class LocalDailyWorkoutStorage implements IDailyWorkoutStorage {
  static const String _fileName = 'valimai_daily_workouts.json';
  Map<String, DailyWorkout>? _cachedRecords;

  @override
  Future<Map<String, DailyWorkout>> loadDailyWorkouts() async {
    if (_cachedRecords != null) {
      return Map<String, DailyWorkout>.from(_cachedRecords!);
    }

    try {
      final content = await StorageHelper.safeReadString(_fileName);
      if (content != null && content.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(content);
        final result = <String, DailyWorkout>{};
        jsonMap.forEach((key, val) {
          result[key] = DailyWorkout.fromJson(val as Map<String, dynamic>);
        });
        _cachedRecords = result;
        return Map<String, DailyWorkout>.from(result);
      }
    } catch (_) {}

    _cachedRecords = <String, DailyWorkout>{};
    return _cachedRecords!;
  }

  @override
  Future<bool> saveDailyWorkout(DailyWorkout record) async {
    _cachedRecords ??= await loadDailyWorkouts();
    // Unique local-date constraint: overwrite or insert for record.localDate
    _cachedRecords![record.localDate] = record;

    try {
      final jsonMap = _cachedRecords!.map((k, v) => MapEntry(k, v.toJson()));
      await StorageHelper.safeWriteString(_fileName, jsonEncode(jsonMap));
      return true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<DailyWorkout?> getDailyWorkoutForDate(String localDate) async {
    _cachedRecords ??= await loadDailyWorkouts();
    return _cachedRecords![localDate];
  }
}
