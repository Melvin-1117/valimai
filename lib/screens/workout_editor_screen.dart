import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/workout_controller.dart';
import '../theme/app_theme.dart';
import 'add_exercise_screen.dart';

class WorkoutEditorScreen extends StatefulWidget {
  final DateTime date;
  final Workout workout;

  const WorkoutEditorScreen({
    super.key,
    required this.date,
    required this.workout,
  });

  @override
  State<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends State<WorkoutEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _targetMusclesController;
  late int _estimatedDuration;
  late List<WorkoutExercise> _exercises;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workout.name);
    _targetMusclesController =
        TextEditingController(text: widget.workout.targetMuscleGroups);
    _estimatedDuration = widget.workout.estimatedDurationMinutes;
    // Clone exercises
    _exercises = List<WorkoutExercise>.from(widget.workout.exercises);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetMusclesController.dispose();
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
    final Set<String> existingNames =
        _exercises.map((e) => e.name.toLowerCase().trim()).toSet();

    final List<Exercise>? selected =
        await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute(
        builder: (_) => AddExerciseScreen(
          existingExerciseNames: existingNames,
        ),
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        for (final ex in selected) {
          final exNameLower = ex.name.toLowerCase().trim();
          // Ensure no duplicates
          if (!_exercises
              .any((e) => e.name.toLowerCase().trim() == exNameLower)) {
            final defaultWeight =
                ex.equipment == EquipmentTypes.bodyweight ? 0.0 : 20.0;

            _exercises.add(
              WorkoutExercise(
                id: 'ex_${DateTime.now().millisecondsSinceEpoch}_${_exercises.length}',
                exerciseId: ex.id,
                name: ex.name,
                targetMuscle: ex.primaryMuscleGroup,
                sets: 3,
                reps: 10,
                weightKg: defaultWeight,
                restSeconds: 90,
                order: _exercises.length,
              ),
            );
          }
        }
      });
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

    final success = await WorkoutController.instance
        .updateWorkoutForDate(widget.date, updatedWorkout);

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
      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
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
      'DEC'
    ];
    final dateStr =
        '${months[widget.date.month]} ${widget.date.day}, ${widget.date.year}';

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
            const Text(
              'WORKOUT EDITOR',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: ValimaiColors.onSurface,
              ),
            ),
            Text(
              'ASSIGNED FOR $dateStr',
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
                  icon: const Icon(Icons.add,
                      size: 16, color: ValimaiColors.primaryContainer),
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
                    backgroundColor:
                        ValimaiColors.primaryContainer.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
                    border:
                        Border.all(color: ValimaiColors.cardBorder, width: 1),
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
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exercises.length,
                onReorder: _onReorder,
                itemBuilder: (context, index) {
                  final ex = _exercises[index];
                  return Container(
                    key: ValueKey(ex.id),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ValimaiColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: ValimaiColors.cardBorder, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exercise title & drag handle row
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: ValimaiColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.name,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: ValimaiColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    ex.targetMuscle,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11,
                                      color: ValimaiColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: ValimaiColors.secondary,
                                size: 18,
                              ),
                              onPressed: () => _removeExercise(index),
                            ),
                            const Icon(
                              Icons.drag_indicator,
                              color: ValimaiColors.secondary,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(
                          color: ValimaiColors.cardBorder,
                          height: 1,
                        ),
                        const SizedBox(height: 10),

                        // Metric Tuning Steppers (Sets, Reps, Weight, Rest)
                        Row(
                          children: [
                            // Sets
                            Expanded(
                              child: _buildMetricTuningTile(
                                label: 'SETS',
                                value: '${ex.sets}',
                                onDec: () {
                                  if (ex.sets > 1) {
                                    _updateExercise(
                                        index, ex.copyWith(sets: ex.sets - 1));
                                  }
                                },
                                onInc: () {
                                  _updateExercise(
                                      index, ex.copyWith(sets: ex.sets + 1));
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Reps
                            Expanded(
                              child: _buildMetricTuningTile(
                                label: 'REPS',
                                value: '${ex.reps}',
                                onDec: () {
                                  if (ex.reps > 1) {
                                    _updateExercise(
                                        index, ex.copyWith(reps: ex.reps - 1));
                                  }
                                },
                                onInc: () {
                                  _updateExercise(
                                      index, ex.copyWith(reps: ex.reps + 1));
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Weight
                            Expanded(
                              child: _buildMetricTuningTile(
                                label: 'KG',
                                value: ex.weightKg % 1 == 0
                                    ? '${ex.weightKg.toInt()}'
                                    : ex.weightKg.toStringAsFixed(1),
                                onDec: () {
                                  if (ex.weightKg > 0) {
                                    _updateExercise(index,
                                        ex.copyWith(weightKg: ex.weightKg - 2.5));
                                  }
                                },
                                onInc: () {
                                  _updateExercise(index,
                                      ex.copyWith(weightKg: ex.weightKg + 2.5));
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Rest
                            Expanded(
                              child: _buildMetricTuningTile(
                                label: 'REST',
                                value: '${ex.restSeconds}s',
                                onDec: () {
                                  if (ex.restSeconds > 15) {
                                    _updateExercise(
                                        index,
                                        ex.copyWith(
                                            restSeconds: ex.restSeconds - 15));
                                  }
                                },
                                onInc: () {
                                  _updateExercise(
                                      index,
                                      ex.copyWith(
                                          restSeconds: ex.restSeconds + 15));
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Prominent Red Save Changes Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveWorkoutChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ValimaiColors.primaryContainer,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      ValimaiColors.primaryContainer.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
            const SizedBox(height: 16),
          ],
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ValimaiColors.cardBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ValimaiColors.cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: ValimaiColors.primaryContainer, width: 1.5),
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
            icon: const Icon(Icons.remove, size: 14, color: ValimaiColors.secondary),
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
            icon: const Icon(Icons.add, size: 14, color: ValimaiColors.secondary),
            onPressed: onIncrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTuningTile({
    required String label,
    required String value,
    required VoidCallback onDec,
    required VoidCallback onInc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: ValimaiColors.secondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: ValimaiColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onDec,
                child: Container(
                  width: 22,
                  height: 20,
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Icon(Icons.remove,
                        size: 11, color: ValimaiColors.secondary),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onInc,
                child: Container(
                  width: 22,
                  height: 20,
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Icon(Icons.add,
                        size: 11, color: ValimaiColors.secondary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

