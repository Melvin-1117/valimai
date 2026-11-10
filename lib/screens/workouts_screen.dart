import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../services/routine_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/valimai_app_bar.dart';
import 'workout_editor_screen.dart';

class WorkoutsScreen extends StatefulWidget {
  final VoidCallback? onStartSession;

  const WorkoutsScreen({super.key, this.onStartSession});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'ALL ROUTINES',
    'ACTIVE ONLY',
    'CHEST',
    'BACK',
    'LEGS',
    'SHOULDERS',
    'ARMS',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WorkoutRoutine> _getFilteredRoutines(List<WorkoutRoutine> all) {
    List<WorkoutRoutine> result = all;

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      result = RoutineController.instance.searchRoutines(_searchQuery);
    }

    // Category filter
    if (_selectedCategoryIndex == 1) {
      // ACTIVE ONLY
      result = result.where((r) => r.isActive).toList();
    } else if (_selectedCategoryIndex > 1) {
      final category = _categories[_selectedCategoryIndex].toLowerCase();
      result = result.where((r) {
        return r.targetMuscleGroups.any(
          (m) => m.toLowerCase().contains(category),
        );
      }).toList();
    }

    return result;
  }

  Future<void> _openCreateRoutineDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final selectedMuscles = <String>{};

    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: ValimaiColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (modalContext, setModalState) {
              final bottomPadding = MediaQuery.of(modalContext)
                  .viewInsets
                  .bottom;
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: bottomPadding + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CREATE WORKOUT ROUTINE',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: ValimaiColors.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: ValimaiColors.secondary,
                            ),
                            onPressed: () =>
                                Navigator.of(modalContext).pop(false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Routine Name
                      const Text(
                        'ROUTINE NAME *',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ValimaiColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Workout E – Arms & Core',
                          hintStyle: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            color: ValimaiColors.secondary,
                          ),
                          filled: true,
                          fillColor: ValimaiColors.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: ValimaiColors.cardBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: ValimaiColors.primaryContainer,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Description
                      const Text(
                        'OPTIONAL DESCRIPTION',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descController,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          color: ValimaiColors.onSurface,
                        ),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g. Bicep peak hypertrophy, triceps, and abdominal bracing',
                          hintStyle: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            color: ValimaiColors.secondary,
                          ),
                          filled: true,
                          fillColor: ValimaiColors.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: ValimaiColors.cardBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: ValimaiColors.primaryContainer,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Target Muscle Groups
                      const Text(
                        'TARGET MUSCLE GROUPS',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: MuscleGroupCategories.all.map((muscle) {
                          final isSelected = selectedMuscles.contains(muscle);
                          return FilterChip(
                            label: Text(muscle),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedMuscles.add(muscle);
                                } else {
                                  selectedMuscles.remove(muscle);
                                }
                              });
                            },
                            labelStyle: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : ValimaiColors.secondary,
                            ),
                            backgroundColor: ValimaiColors.surfaceContainerLow,
                            selectedColor: ValimaiColors.primaryContainer,
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected
                                    ? ValimaiColors.primaryContainer
                                    : ValimaiColors.cardBorder,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final name = nameController.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a routine name.',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                final newRoutine = await RoutineController
                                    .instance
                                    .createRoutine(
                                      name: name,
                                      description: descController.text.trim(),
                                      targetMuscleGroups: selectedMuscles
                                          .toList(),
                                    );

                                if (context.mounted) {
                                  Navigator.of(modalContext).pop(true);
                                  if (newRoutine != null) {
                                    _openRoutineEditor(newRoutine);
                                  }
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ValimaiColors.onSurface,
                                side: const BorderSide(
                                  color: ValimaiColors.cardBorder,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                '+ ADD EXERCISES',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final name = nameController.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a routine name.',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                await RoutineController.instance.createRoutine(
                                  name: name,
                                  description: descController.text.trim(),
                                  targetMuscleGroups: selectedMuscles.toList(),
                                );

                                if (context.mounted) {
                                  Navigator.of(modalContext).pop(true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ValimaiColors.primaryContainer,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'CREATE ROUTINE',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Routine created successfully!'),
            backgroundColor: ValimaiColors.primaryContainer,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      nameController.dispose();
      descController.dispose();
    }
  }

  Future<void> _openRoutineEditor(WorkoutRoutine routine) async {
    final workout = routine.toWorkout();
    final updatedWorkout = await Navigator.of(context).push<Workout>(
      MaterialPageRoute(
        builder: (_) => WorkoutEditorScreen(
          workout: workout,
          customTitle: 'EDIT ROUTINE',
          customSubtitle: routine.name.toUpperCase(),
          onSave: (updated) async {
            final updatedRoutine = routine.updateFromWorkout(updated);
            return await RoutineController.instance.updateRoutine(
              updatedRoutine,
            );
          },
        ),
      ),
    );

    if (updatedWorkout != null && mounted) {
      setState(() {});
    }
  }

  Future<void> _showRenameDialog(WorkoutRoutine routine) async {
    final nameController = TextEditingController(text: routine.name);
    final descController = TextEditingController(text: routine.description);
    final selectedMuscles = Set<String>.from(routine.targetMuscleGroups);

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (dialogCtx, setDialogState) {
              return AlertDialog(
                backgroundColor: ValimaiColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: ValimaiColors.cardBorder),
                ),
                title: const Text(
                  'RENAME ROUTINE',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ROUTINE NAME',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ValimaiColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: ValimaiColors.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: ValimaiColors.cardBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descController,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          color: ValimaiColors.onSurface,
                        ),
                        maxLines: 2,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: ValimaiColors.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: ValimaiColors.cardBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'TARGET MUSCLES',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: MuscleGroupCategories.all.map((m) {
                          final isSel = selectedMuscles.contains(m);
                          return FilterChip(
                            label: Text(
                              m,
                              style: const TextStyle(fontSize: 10),
                            ),
                            selected: isSel,
                            onSelected: (val) {
                              setDialogState(() {
                                if (val) {
                                  selectedMuscles.add(m);
                                } else {
                                  selectedMuscles.remove(m);
                                }
                              });
                            },
                            backgroundColor: ValimaiColors.surfaceContainerLow,
                            selectedColor: ValimaiColors.primaryContainer,
                            checkmarkColor: Colors.white,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isNotEmpty) {
                        Navigator.of(ctx).pop(true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ValimaiColors.primaryContainer,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'SAVE',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed == true) {
        await RoutineController.instance.renameRoutine(
          routine.id,
          nameController.text.trim(),
          description: descController.text.trim(),
          targetMuscleGroups: selectedMuscles.toList(),
        );
      }
    } finally {
      nameController.dispose();
      descController.dispose();
    }
  }

  Future<void> _showDeleteConfirmation(WorkoutRoutine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ValimaiColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ValimaiColors.cardBorder),
          ),
          title: const Text(
            'DELETE WORKOUT ROUTINE',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.redAccent,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${routine.name}"?\n\nAll ${routine.totalExercises} exercises and set configurations in this routine will be removed.',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              color: ValimaiColors.secondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  color: ValimaiColors.secondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ValimaiColors.primaryContainer,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'DELETE',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await RoutineController.instance.deleteRoutine(routine.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${routine.name}"'),
            backgroundColor: ValimaiColors.surfaceContainerHighest,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showRoutineDetailsSheet(WorkoutRoutine routine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ValimaiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final exercises = routine.exercises;
        final rotationLabel = String.fromCharCode(
          65 + (routine.rotationOrder % 26),
        );

        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ValimaiColors.primaryContainer.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ROUTINE $rotationLabel // ROTATION #${routine.rotationOrder + 1}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: ValimaiColors.primaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: ValimaiColors.secondary,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title & Description
              Text(
                routine.name,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ValimaiColors.onSurface,
                ),
              ),
              if (routine.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  routine.description,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Target muscles tags
              if (routine.targetMuscleGroups.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: routine.targetMuscleGroups.map((m) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        m.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ValimaiColors.primaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 14),

              // Metrics Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailMetric(
                      'EXERCISES',
                      '${routine.totalExercises}',
                    ),
                    _buildDetailMetric('SETS', '${routine.totalSets}'),
                    _buildDetailMetric(
                      'EST. TIME',
                      '~${routine.estimatedDurationMinutes}m',
                    ),
                    _buildDetailMetric(
                      'STATUS',
                      routine.isActive ? 'ACTIVE' : 'PAUSED',
                      isHighlight: routine.isActive,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'EXERCISES & SET BREAKDOWN',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: ValimaiColors.secondary,
                ),
              ),
              const SizedBox(height: 10),

              // Exercises List
              Expanded(
                child: exercises.isEmpty
                    ? const Center(
                        child: Text(
                          'No exercises in this routine.\nTap "EDIT IN WORKOUT EDITOR" to add exercises.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            color: ValimaiColors.secondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: exercises.length,
                        itemBuilder: (context, i) {
                          final ex = exercises[i];
                          final sets = ex.effectiveSets;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ValimaiColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: ValimaiColors.cardBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color:
                                            ValimaiColors.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: const TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                ValimaiColors.primaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ex.name,
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: ValimaiColors.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${ex.targetMuscle} • ${ex.equipment ?? "Free Weight"}',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                    color: ValimaiColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Sets chips
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: sets.map((s) {
                                    final w = s.weightKg % 1 == 0
                                        ? '${s.weightKg.toInt()}'
                                        : s.weightKg.toStringAsFixed(1);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ValimaiColors
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'S${s.setNumber}: ${s.reps}×${w}kg',
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: ValimaiColors.onSurface,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 14),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _openRoutineEditor(routine);
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text(
                    'EDIT IN WORKOUT EDITOR',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ValimaiColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailMetric(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: ValimaiColors.secondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isHighlight
                ? ValimaiColors.primaryContainer
                : ValimaiColors.onSurface,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ValimaiColors.background,
      appBar: const ValimaiAppBar(title: 'Workouts', showSearch: false),
      body: ListenableBuilder(
        listenable: RoutineController.instance,
        builder: (context, _) {
          final allRoutines = RoutineController.instance.allRoutines;
          final routines = _getFilteredRoutines(allRoutines);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                _buildSearchBar(),
                const SizedBox(height: 12),

                // Category Filter Carousel
                _buildCategoryFilters(),
                const SizedBox(height: 20),

                // Routines Header & + Add Routine Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.view_agenda_outlined,
                              color: ValimaiColors.primaryContainer,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'WORKOUT ROUTINES',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: ValimaiColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${routines.length} Reusable Routines • Drag to reorder rotation',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 10,
                            color: ValimaiColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _openCreateRoutineDialog,
                      icon: const Icon(Icons.add, size: 15),
                      label: const Text(
                        'NEW ROUTINE',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ValimaiColors.primaryContainer,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Routines List
                if (routines.isEmpty)
                  _buildEmptyState()
                else if (_searchQuery.isNotEmpty || _selectedCategoryIndex > 0)
                  // Static ListView while searching/filtering
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      return _buildRoutineCard(
                        routines[index],
                        canReorder: false,
                      );
                    },
                  )
                else
                  // Reorderable list for rotation sequencing
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: routines.length,
                    onReorder: (oldIndex, newIndex) {
                      RoutineController.instance.reorderRoutines(
                        oldIndex,
                        newIndex,
                      );
                    },
                    itemBuilder: (context, index) {
                      return _buildRoutineCard(
                        routines[index],
                        canReorder: true,
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // Routine Workshop Section
                const Text(
                  'WORKSHOP',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: ValimaiColors.secondary,
                  ),
                ),
                const SizedBox(height: 10),

                _buildActionCard(
                  icon: Icons.add_circle_outline,
                  title: 'Create Custom Routine',
                  subtitle: 'Set target metrics, set structure, and cues',
                  onTap: _openCreateRoutineDialog,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.fitness_center,
            size: 40,
            color: ValimaiColors.secondary,
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'No routines match "$_searchQuery"'
                : (_selectedCategoryIndex == 0
                      ? 'No workout routines created yet.\nCreate your first routine to start training!'
                      : 'No routines found in this category.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ValimaiColors.secondary,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _openCreateRoutineDialog,
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'CREATE FIRST ROUTINE',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: ValimaiColors.primaryContainer,
              side: const BorderSide(color: ValimaiColors.primaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, color: ValimaiColors.secondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                color: ValimaiColors.onSurface,
              ),
              decoration: const InputDecoration(
                hintText: 'Search routines, muscles, exercises...',
                hintStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: ValimaiColors.secondary,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Icon(
                Icons.close,
                size: 16,
                color: ValimaiColors.secondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategoryIndex = index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ValimaiColors.primaryContainer
                      : ValimaiColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? ValimaiColors.primaryContainer
                        : ValimaiColors.cardBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isSelected ? Colors.white : ValimaiColors.secondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRoutineCard(WorkoutRoutine routine, {required bool canReorder}) {
    final rotationLetter = String.fromCharCode(
      65 + (routine.rotationOrder % 26),
    );
    final previewChips = routine.exercises.take(3).map((e) => e.name).toList();

    return Container(
      key: ValueKey(routine.id),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Left red accent indicator for active routines
          if (routine.isActive)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: ValimaiColors.primaryContainer),
            ),

          Padding(
            padding: EdgeInsets.only(
              left: routine.isActive ? 18 : 14,
              right: 14,
              top: 14,
              bottom: 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Rotation tag + Active toggle + Drag handle + Popup menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ROUTINE $rotationLetter',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: ValimaiColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            RoutineController.instance.toggleRoutineActive(
                              routine.id,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: routine.isActive
                                  ? ValimaiColors.primaryContainer.withOpacity(
                                      0.15,
                                    )
                                  : ValimaiColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              routine.isActive ? 'ACTIVE' : 'PAUSED',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: routine.isActive
                                    ? ValimaiColors.primaryContainer
                                    : ValimaiColors.secondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (canReorder) ...[
                          const Icon(
                            Icons.drag_indicator,
                            size: 18,
                            color: ValimaiColors.secondary,
                          ),
                          const SizedBox(width: 6),
                        ],
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            size: 18,
                            color: ValimaiColors.secondary,
                          ),
                          color: ValimaiColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              color: ValimaiColors.cardBorder,
                            ),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'details':
                                _showRoutineDetailsSheet(routine);
                                break;
                              case 'edit':
                                _openRoutineEditor(routine);
                                break;
                              case 'rename':
                                _showRenameDialog(routine);
                                break;
                              case 'toggle':
                                RoutineController.instance.toggleRoutineActive(
                                  routine.id,
                                );
                                break;
                              case 'delete':
                                _showDeleteConfirmation(routine);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'details',
                              child: Text(
                                'View Details',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text(
                                'Edit Exercises & Sets',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'rename',
                              child: Text(
                                'Rename / Edit Info',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                routine.isActive
                                    ? 'Mark Inactive'
                                    : 'Mark Active',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete Routine',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Routine Title
                Text(
                  routine.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                if (routine.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    routine.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // Metrics row: Movements, Volume (Sets), Est Time
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MOVEMENTS',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${routine.totalExercises} Units',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VOLUME',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${routine.totalSets} Sets',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DURATION',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '~${routine.estimatedDurationMinutes} Mins',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Target Muscle Badges
                if (routine.targetMuscleGroups.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: routine.targetMuscleGroups.map((muscle) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: ValimaiColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          muscle,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: ValimaiColors.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                // Preview Chips of exercises
                if (previewChips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: previewChips.map((chip) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: ValimaiColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            chip,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 10,
                              color: ValimaiColors.secondary,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),

                // Card Footer Actions: Details & Edit
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _showRoutineDetailsSheet(routine),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ValimaiColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 13,
                              color: ValimaiColors.secondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'DETAILS',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _openRoutineEditor(routine),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: ValimaiColors.primaryContainer.withOpacity(
                            0.14,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: ValimaiColors.primaryContainer.withOpacity(
                              0.35,
                            ),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              size: 12,
                              color: ValimaiColors.primaryContainer,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'EDIT IN EDITOR',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: ValimaiColors.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ValimaiColors.cardBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: ValimaiColors.primaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ValimaiColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right,
              color: ValimaiColors.secondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
