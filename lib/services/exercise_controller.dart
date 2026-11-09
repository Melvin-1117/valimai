import 'package:flutter/foundation.dart';

import '../models/exercise.dart';
import 'exercise_storage.dart';

class ExerciseController extends ChangeNotifier {
  static ExerciseController _instance = ExerciseController._internal();
  static ExerciseController get instance => _instance;

  @visibleForTesting
  static void setInstance(ExerciseController customInstance) {
    _instance = customInstance;
  }

  final IExerciseStorage _storage;

  ExerciseController({IExerciseStorage? storage})
    : _storage = storage ?? LocalExerciseStorage();

  ExerciseController._internal({IExerciseStorage? storage})
    : _storage = storage ?? LocalExerciseStorage();

  bool _isInitialized = false;
  bool _isLoading = false;
  List<Exercise> _exercises = [];
  String? _lastError;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  List<Exercise> get allExercises => List.unmodifiable(_exercises);
  String? get lastError => _lastError;

  /// Initialize and load all exercises (presets + custom)
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      _exercises = await _storage.loadExercises();
      _isInitialized = true;
    } catch (e) {
      _lastError = 'Failed to load exercises: $e';
      debugPrint(_lastError);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get exercises filtered by category (or all if category is null/empty)
  List<Exercise> getExercisesByCategory(String? category) {
    if (category == null || category.trim().isEmpty || category == 'ALL') {
      return List.unmodifiable(_exercises);
    }

    final catLower = category.toLowerCase().trim();
    return _exercises.where((ex) {
      if (ex.primaryMuscleGroup.toLowerCase().trim() == catLower) {
        return true;
      }
      return ex.secondaryMuscleGroups.any(
        (s) => s.toLowerCase().trim() == catLower,
      );
    }).toList();
  }

  /// Count available exercises for a specific muscle group
  int countByCategory(String category) {
    final catLower = category.toLowerCase().trim();
    return _exercises.where((ex) {
      return ex.primaryMuscleGroup.toLowerCase().trim() == catLower ||
          ex.secondaryMuscleGroups.any(
            (s) => s.toLowerCase().trim() == catLower,
          );
    }).length;
  }

  /// Search across exercises with optional category filter
  List<Exercise> searchExercises(String query, {String? category}) {
    final q = query.toLowerCase().trim();
    final baseList = getExercisesByCategory(category);

    if (q.isEmpty) {
      return baseList;
    }

    return baseList.where((ex) {
      final nameMatches = ex.name.toLowerCase().contains(q);
      final primaryMatches = ex.primaryMuscleGroup.toLowerCase().contains(q);
      final equipmentMatches = ex.equipment.toLowerCase().contains(q);
      final secondaryMatches = ex.secondaryMuscleGroups.any(
        (sec) => sec.toLowerCase().contains(q),
      );

      return nameMatches ||
          primaryMatches ||
          equipmentMatches ||
          secondaryMatches;
    }).toList();
  }

  /// Find an exercise by its unique id
  Exercise? getExerciseById(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Find an exercise by its name (case-insensitive)
  Exercise? getExerciseByName(String name) {
    final lower = name.toLowerCase().trim();
    try {
      return _exercises.firstWhere((e) => e.name.toLowerCase().trim() == lower);
    } catch (_) {
      return null;
    }
  }

  /// Add a new custom exercise with validation
  Future<Exercise?> addCustomExercise({
    required String name,
    required String primaryMuscleGroup,
    List<String> secondaryMuscleGroups = const [],
    required String equipment,
  }) async {
    _lastError = null;

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _lastError = 'Exercise name cannot be empty.';
      notifyListeners();
      return null;
    }

    // Check duplicate
    final nameLower = trimmedName.toLowerCase();
    final isDuplicate = _exercises.any(
      (e) => e.name.toLowerCase().trim() == nameLower,
    );
    if (isDuplicate) {
      _lastError = 'An exercise named "$trimmedName" already exists.';
      notifyListeners();
      return null;
    }

    final newExercise = Exercise(
      id: 'custom_ex_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmedName,
      primaryMuscleGroup: primaryMuscleGroup,
      secondaryMuscleGroups: secondaryMuscleGroups,
      equipment: equipment,
      isCustom: true,
      createdAt: DateTime.now(),
    );

    _exercises.add(newExercise);
    notifyListeners();

    try {
      final success = await _storage.saveCustomExercise(newExercise);
      if (!success) {
        _lastError = 'Failed to persist custom exercise locally.';
      }
      return newExercise;
    } catch (e) {
      _lastError = 'Error saving exercise: $e';
      return newExercise;
    }
  }
}
