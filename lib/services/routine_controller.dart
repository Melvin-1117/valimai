import 'package:flutter/foundation.dart';

import '../models/routine.dart';
import '../models/workout.dart';
import 'routine_storage.dart';
import 'workout_controller.dart';

class RoutineController extends ChangeNotifier {
  static RoutineController _instance = RoutineController._internal();
  static RoutineController get instance => _instance;

  @visibleForTesting
  static void setInstance(RoutineController customInstance) {
    _instance = customInstance;
  }

  final IRoutineStorage _storage;

  RoutineController({IRoutineStorage? storage})
    : _storage = storage ?? LocalRoutineStorage();

  RoutineController._internal({IRoutineStorage? storage})
    : _storage = storage ?? LocalRoutineStorage();

  bool _isInitialized = false;
  bool _isLoading = false;
  List<WorkoutRoutine> _routines = [];
  String? _lastError;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// All routines sorted by rotationOrder
  List<WorkoutRoutine> get allRoutines => List.unmodifiable(_routines);

  /// Only active routines
  List<WorkoutRoutine> get activeRoutines =>
      List.unmodifiable(_routines.where((r) => r.isActive));

  /// Initialize and load routines from persistent storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      _routines = await _storage.loadRoutines();
      _routines.sort((a, b) => a.rotationOrder.compareTo(b.rotationOrder));
      _isInitialized = true;
    } catch (e) {
      _lastError = 'Failed to load routines: $e';
      debugPrint(_lastError);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new routine
  Future<WorkoutRoutine?> createRoutine({
    required String name,
    String description = '',
    List<String> targetMuscleGroups = const [],
    List<RoutineExercise> exercises = const [],
  }) async {
    _lastError = null;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _lastError = 'Routine name cannot be empty.';
      notifyListeners();
      return null;
    }

    final now = DateTime.now();
    final newId = 'routine_${now.millisecondsSinceEpoch}_${_routines.length}';
    final rotationOrder = _routines.length;

    final newRoutine = WorkoutRoutine(
      id: newId,
      name: trimmedName,
      description: description.trim(),
      targetMuscleGroups: List<String>.from(targetMuscleGroups),
      rotationOrder: rotationOrder,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      exercises: exercises,
    );

    _routines.add(newRoutine);
    notifyListeners();

    try {
      final success = await _storage.saveRoutine(newRoutine);
      if (!success) {
        _lastError = 'Failed to persist routine locally.';
      }
      return newRoutine;
    } catch (e) {
      _lastError = 'Error saving routine: $e';
      return newRoutine;
    }
  }

  /// Update an existing routine
  Future<bool> updateRoutine(WorkoutRoutine routine) async {
    _lastError = null;
    final index = _routines.indexWhere((r) => r.id == routine.id);
    if (index < 0) {
      _lastError = 'Routine not found.';
      notifyListeners();
      return false;
    }

    final updated = routine.copyWith(updatedAt: DateTime.now());
    _routines[index] = updated;
    notifyListeners();

    try {
      return await _storage.saveRoutine(updated);
    } catch (e) {
      _lastError = 'Failed to update routine: $e';
      return false;
    }
  }

  /// Update an existing routine template directly from a Workout edited in WorkoutEditorScreen
  Future<bool> updateRoutineFromWorkout(Workout workout) async {
    final existing = getRoutineById(workout.id);
    if (existing == null) return false;
    final updated = existing.updateFromWorkout(workout);
    return await updateRoutine(updated);
  }

  /// Rename a routine with optional description and muscle updates
  Future<bool> renameRoutine(
    String id,
    String newName, {
    String? description,
    List<String>? targetMuscleGroups,
  }) async {
    _lastError = null;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      _lastError = 'Routine name cannot be empty.';
      notifyListeners();
      return false;
    }

    final index = _routines.indexWhere((r) => r.id == id);
    if (index < 0) {
      _lastError = 'Routine not found.';
      return false;
    }

    final current = _routines[index];
    final updated = current.copyWith(
      name: trimmed,
      description: description?.trim() ?? current.description,
      targetMuscleGroups: targetMuscleGroups ?? current.targetMuscleGroups,
      updatedAt: DateTime.now(),
    );

    _routines[index] = updated;
    notifyListeners();

    try {
      return await _storage.saveRoutine(updated);
    } catch (e) {
      _lastError = 'Failed to rename routine: $e';
      return false;
    }
  }

  /// Delete a routine with automatic renumbering of rotation order
  Future<bool> deleteRoutine(String id) async {
    _lastError = null;
    final index = _routines.indexWhere((r) => r.id == id);
    if (index < 0) {
      return false;
    }

    _routines.removeAt(index);
    // Renumber remaining routines
    for (int i = 0; i < _routines.length; i++) {
      _routines[i] = _routines[i].copyWith(rotationOrder: i);
    }
    notifyListeners();

    try {
      await WorkoutController.instance.handleRoutineDeleted(id);
      return await _storage.deleteRoutine(id);
    } catch (e) {
      _lastError = 'Failed to delete routine: $e';
      return false;
    }
  }

  /// Reorder routines for rotation sequencing
  Future<bool> reorderRoutines(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= _routines.length ||
        newIndex < 0 ||
        newIndex > _routines.length) {
      return false;
    }

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = _routines.removeAt(oldIndex);
    _routines.insert(newIndex, item);

    // Re-index rotationOrder
    for (int i = 0; i < _routines.length; i++) {
      _routines[i] = _routines[i].copyWith(rotationOrder: i);
    }
    notifyListeners();

    try {
      return await _storage.saveAllRoutines(_routines);
    } catch (e) {
      _lastError = 'Failed to reorder routines: $e';
      return false;
    }
  }

  /// Toggle active state of a routine
  Future<bool> toggleRoutineActive(String id) async {
    final index = _routines.indexWhere((r) => r.id == id);
    if (index < 0) return false;

    final current = _routines[index];
    final updated = current.copyWith(
      isActive: !current.isActive,
      updatedAt: DateTime.now(),
    );

    _routines[index] = updated;
    notifyListeners();

    try {
      return await _storage.saveRoutine(updated);
    } catch (e) {
      _lastError = 'Failed to toggle active status: $e';
      return false;
    }
  }

  /// Find a routine by its ID
  WorkoutRoutine? getRoutineById(String id) {
    try {
      return _routines.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Search across routines
  List<WorkoutRoutine> searchRoutines(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return allRoutines;
    }

    return _routines.where((r) {
      final nameMatches = r.name.toLowerCase().contains(q);
      final descMatches = r.description.toLowerCase().contains(q);
      final muscleMatches = r.targetMuscleGroups.any(
        (m) => m.toLowerCase().contains(q),
      );
      final exerciseMatches = r.exercises.any(
        (e) => e.name.toLowerCase().contains(q),
      );

      return nameMatches || descMatches || muscleMatches || exerciseMatches;
    }).toList();
  }
}
