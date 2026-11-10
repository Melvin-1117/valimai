import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/routine_controller.dart';
import '../services/workout_controller.dart';
import '../theme/app_theme.dart';
import 'add_exercise_screen.dart';
import 'exercise_configuration_screen.dart';

class WorkoutEditorScreen extends StatefulWidget {
  final DateTime? date;
  final Workout workout;
  final String? customTitle;
  final String? customSubtitle;
  final Future<bool> Function(Workout updatedWorkout)? onSave;

  const WorkoutEditorScreen({
    super.key,
    this.date,
    required this.workout,
    this.customTitle,
    this.customSubtitle,
    this.onSave,
  });

  @override
  State<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends State<WorkoutEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _targetMusclesController;
  late TextEditingController _searchController;
  late int _estimatedDuration;
  late List<WorkoutExercise> _exercises;
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workout.name);
    _targetMusclesController = TextEditingController(
      text: widget.workout.targetMuscleGroups,
    );
    _searchController = TextEditingController();
    _estimatedDuration = widget.workout.estimatedDurationMinutes;
    // Clone exercises
    _exercises = List<WorkoutExercise>.from(widget.workout.exercises);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetMusclesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
      // Re-index orders
      for (int i = 0; i < _exercises.length; i++) {
        _exercises[i] = _exercises[i].copyWith(order: i);
      }
    });
  }

  Future<void> _openAddExerciseScreen() async {
    final Set<String> existingNames = _exercises
        .map((e) => e.name.toLowerCase().trim())
        .toSet();

    final List<Exercise>? selected = await Navigator.of(context)
        .push<List<Exercise>>(
          MaterialPageRoute(
            builder: (_) =>
                AddExerciseScreen(existingExerciseNames: existingNames),
          ),
        );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        for (final ex in selected) {
          final exNameLower = ex.name.toLowerCase().trim();
          // Ensure no duplicates
          if (!_exercises.any(
            (e) => e.name.toLowerCase().trim() == exNameLower,
          )) {
            final defaultWeight = ex.equipment == EquipmentTypes.bodyweight
                ? 0.0
                : 20.0;

            final defaultSets = List.generate(
              3,
              (i) => ExerciseSetConfig(
                setNumber: i + 1,
                reps: 10,
                weightKg: defaultWeight,
              ),
            );

            _exercises.add(
              WorkoutExercise(
                id: 'ex_${DateTime.now().millisecondsSinceEpoch}_${_exercises.length}',
                exerciseId: ex.id,
                name: ex.name,
                targetMuscle: ex.primaryMuscleGroup,
                setConfigs: defaultSets,
                sets: 3,
                reps: 10,
                weightKg: defaultWeight,
                order: _exercises.length,
                equipment: ex.equipment,
                secondaryMuscles: ex.secondaryMuscleGroups,
              ),
            );
          }
        }
      });
    }
  }

  Future<void> _openExerciseConfiguration(int exerciseIndex) async {
    final currentExercise = _exercises[exerciseIndex];
    final WorkoutExercise? updated = await Navigator.of(context)
        .push<WorkoutExercise>(
          MaterialPageRoute(
            builder: (_) =>
                ExerciseConfigurationScreen(workoutExercise: currentExercise),
          ),
        );

    if (updated != null) {
      _updateExercise(exerciseIndex, updated);
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
      for (int i = 0; i < _exercises.length; i++) {
        _exercises[i] = _exercises[i].copyWith(order: i);
      }
    });
  }

  void _updateExercise(int index, WorkoutExercise updated) {
    setState(() {
      _exercises[index] = updated;
    });
  }

  Future<void> _saveWorkoutChanges() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final updatedWorkout = widget.workout.copyWith(
      name: _nameController.text.trim().isEmpty
          ? widget.workout.name
          : _nameController.text.trim(),
      targetMuscleGroups: _targetMusclesController.text.trim().isEmpty
          ? widget.workout.targetMuscleGroups
          : _targetMusclesController.text.trim(),
      estimatedDurationMinutes: _estimatedDuration,
      exercises: _exercises,
    );

    bool success;
    if (widget.onSave != null) {
      try {
        success = await widget.onSave!(updatedWorkout);
      } catch (e) {
        debugPrint('Error saving workout via onSave: $e');
        success = false;
      }
    } else if (widget.date != null) {
      try {
        success = await WorkoutController.instance.updateWorkoutForDate(
          widget.date!,
          updatedWorkout,
        );
      } catch (e) {
        debugPrint('Error updating workout for date: $e');
        success = true;
      }
      // If this corresponds to an underlying routine template, update the template so future uses reflect changes
      try {
        final existing = RoutineController.instance.getRoutineById(
          widget.workout.id,
        );
        if (existing != null) {
          await RoutineController.instance.updateRoutineFromWorkout(
            updatedWorkout,
          );
        }
      } catch (_) {}
    } else {
      success = true;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Workout modifications saved successfully!',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          backgroundColor: ValimaiColors.primaryContainer,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(updatedWorkout);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to save modifications. Please try again.',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  List<MapEntry<int, WorkoutExercise>> _getFilteredExercises() {
    final query = _searchQuery.trim().toLowerCase();
    final List<MapEntry<int, WorkoutExercise>> result = [];
    for (int i = 0; i < _exercises.length; i++) {
      final ex = _exercises[i];
      if (query.isEmpty ||
          ex.name.toLowerCase().contains(query) ||
          ex.targetMuscle.toLowerCase().contains(query) ||
          (ex.equipment != null &&
              ex.equipment!.toLowerCase().contains(query))) {
        result.add(MapEntry(i, ex));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    String dateStr = '';
    if (widget.date != null) {
      final months = [
        '',
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      dateStr =
          '${months[widget.date!.month]} ${widget.date!.day}, ${widget.date!.year}';
    }

    final filtered = _getFilteredExercises();

    return Scaffold(
      backgroundColor: ValimaiColors.background,
      appBar: AppBar(
        backgroundColor: ValimaiColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ValimaiColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customTitle ?? 'WORKOUT EDITOR',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: ValimaiColors.onSurface,
              ),
            ),
            Text(
              widget.customSubtitle ??
                  (widget.date != null
                      ? 'ASSIGNED FOR $dateStr'
                      : 'CUSTOM ROUTINE'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: ValimaiColors.primaryContainer,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveWorkoutChanges,
            child: const Text(
              'SAVE',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: ValimaiColors.primaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: ValimaiColors.cardBorder, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WORKOUT OVERVIEW SECTION
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ValimaiColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ValimaiColors.cardBorder, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('WORKOUT NAME'),
                  const SizedBox(height: 6),
                  _buildTextField(_nameController, 'e.g. Push Hypertrophy'),
                  const SizedBox(height: 12),
                  _buildInputLabel('TARGET MUSCLE GROUPS'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    _targetMusclesController,
                    'e.g. Pectorals, Anterior Deltoids, Lateral Triceps',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInputLabel('ESTIMATED DURATION (MINS)'),
                      _buildStepper(
                        value: '$_estimatedDuration min',
                        onDecrement: () {
                          if (_estimatedDuration > 15) {
                            setState(() => _estimatedDuration -= 5);
                          }
                        },
                        onIncrement: () {
                          setState(() => _estimatedDuration += 5);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // EXERCISES HEADER & SEQUENCE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EXERCISES & SEQUENCE',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_exercises.length} Exercises • ${_exercises.fold(0, (s, e) => s + e.sets)} Total Sets',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _openAddExerciseScreen,
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                    color: ValimaiColors.primaryContainer,
                  ),
                  label: const Text(
                    'Add Exercise',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.primaryContainer,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: ValimaiColors.primaryContainer.withOpacity(
                      0.12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // EXERCISE SEARCH BAR IN WORKOUT
            if (_exercises.isNotEmpty) ...[
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: ValimaiColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ValimaiColors.cardBorder, width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    color: ValimaiColors.onSurface,
                  ),
                  cursorColor: ValimaiColors.primaryContainer,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search exercises in workout...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      color: ValimaiColors.secondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: ValimaiColors.secondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: ValimaiColors.secondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // EXERCISE CARDS
            if (_exercises.isEmpty)
              GestureDetector(
                onTap: _openAddExerciseScreen,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ValimaiColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ValimaiColors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'No exercises in this workout. Tap "+ Add Exercise" to add one.',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                  ),
                ),
              )
            else if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ValimaiColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ValimaiColors.cardBorder, width: 1),
                ),
                child: Center(
                  child: Text(
                    'No exercises match "$_searchQuery"',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ),
              )
            else if (_searchQuery.isNotEmpty)
              // Filtered list (non-reorderable while searching)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final originalIndex = filtered[i].key;
                  final ex = filtered[i].value;
                  return _buildExerciseCard(
                    originalIndex,
                    ex,
                    canReorder: false,
                  );
                },
              )
            else
              // Full sequence with drag-and-drop reordering
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exercises.length,
                onReorder: _onReorder,
                itemBuilder: (context, index) {
                  final ex = _exercises[index];
                  return _buildExerciseCard(index, ex, canReorder: true);
                },
              ),

            const SizedBox(height: 24),

            // Prominent Red Save Changes Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveWorkoutChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ValimaiColors.primaryContainer,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: ValimaiColors.primaryContainer
                      .withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'SAVE WORKOUT CHANGES',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
    int originalIndex,
    WorkoutExercise ex, {
    required bool canReorder,
  }) {
    final sets = ex.effectiveSetConfigs;
    final primaryMuscle = ex.targetMuscle;
    final equipment = ex.equipment ?? EquipmentTypes.barbell;

    // Compact summary string of sets (e.g., "10×20kg, 10×25kg, 8×30kg")
    final setsSummary = sets
        .map((s) {
          final wStr = s.weightKg % 1 == 0
              ? '${s.weightKg.toInt()}'
              : s.weightKg.toStringAsFixed(1);
          return '${s.reps}×${wStr}kg';
        })
        .join(' • ');

    return Container(
      key: ValueKey(ex.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ValimaiColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openExerciseConfiguration(originalIndex),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Index badge + Muscle Icon + Name + Equipment + Drag handle / delete
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Exercise Sequence Badge
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${originalIndex + 1}',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: ValimaiColors.primaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Athletic Icon thumbnail
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ValimaiColors.primaryContainer.withOpacity(
                            0.2,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          MuscleGroupCategories.getIcon(primaryMuscle),
                          color: ValimaiColors.primaryContainer,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Exercise Title & Tags
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.name,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: ValimaiColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ex.targetMuscle} • $equipment',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: ValimaiColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action buttons: Delete & Drag Handle
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: ValimaiColors.secondary,
                        size: 18,
                      ),
                      onPressed: () => _removeExercise(originalIndex),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    if (canReorder) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.drag_indicator,
                        color: ValimaiColors.secondary,
                        size: 20,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(color: ValimaiColors.cardBorder, height: 1),
                const SizedBox(height: 10),

                // Set Breakdown Summary & Rest Indicator
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Sets badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ValimaiColors.primaryContainer.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${sets.length} ${sets.length == 1 ? "SET" : "SETS"}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: ValimaiColors.primaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Summary breakdown
                    Expanded(
                      child: Text(
                        setsSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ValimaiColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Configure Arrow Button
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: ValimaiColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: ValimaiColors.secondary,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ValimaiColors.onSurface,
      ),
      cursorColor: ValimaiColors.primaryContainer,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 13,
          color: ValimaiColors.secondary,
        ),
        filled: true,
        fillColor: ValimaiColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: ValimaiColors.cardBorder,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: ValimaiColors.cardBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: ValimaiColors.primaryContainer,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStepper({
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.remove,
              size: 14,
              color: ValimaiColors.secondary,
            ),
            onPressed: onDecrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ValimaiColors.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.add,
              size: 14,
              color: ValimaiColors.secondary,
            ),
            onPressed: onIncrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
