import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/exercise_controller.dart';
import '../theme/app_theme.dart';

class ExerciseConfigurationScreen extends StatefulWidget {
  final WorkoutExercise workoutExercise;
  final Exercise? exerciseMetadata;

  const ExerciseConfigurationScreen({
    super.key,
    required this.workoutExercise,
    this.exerciseMetadata,
  });

  @override
  State<ExerciseConfigurationScreen> createState() =>
      _ExerciseConfigurationScreenState();
}

class _ExerciseConfigurationScreenState
    extends State<ExerciseConfigurationScreen> {
  late List<ExerciseSetConfig> _setConfigs;
  Exercise? _metadata;

  @override
  void initState() {
    super.initState();
    // Clone setConfigs from effectiveSetConfigs
    _setConfigs = List<ExerciseSetConfig>.from(
      widget.workoutExercise.effectiveSetConfigs.map(
        (s) => ExerciseSetConfig(
          setNumber: s.setNumber,
          reps: s.reps,
          weightKg: s.weightKg,
        ),
      ),
    );

    // Resolve exercise metadata if not passed directly
    _metadata = widget.exerciseMetadata;
    if (_metadata == null) {
      if (widget.workoutExercise.exerciseId != null) {
        _metadata = ExerciseController.instance.getExerciseById(
          widget.workoutExercise.exerciseId!,
        );
      }
      _metadata ??= ExerciseController.instance.getExerciseByName(
        widget.workoutExercise.name,
      );
    }
  }

  void _renumberSets() {
    for (int i = 0; i < _setConfigs.length; i++) {
      _setConfigs[i] = _setConfigs[i].copyWith(setNumber: i + 1);
    }
  }

  void _addSet() {
    setState(() {
      final prevSet = _setConfigs.isNotEmpty
          ? _setConfigs.last
          : const ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 20.0);

      _setConfigs.add(
        ExerciseSetConfig(
          setNumber: _setConfigs.length + 1,
          reps: prevSet.reps,
          weightKg: prevSet.weightKg,
        ),
      );
    });
  }

  void _removeSet(int index) {
    if (_setConfigs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'At least 1 set is required for each exercise.',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          backgroundColor: ValimaiColors.surfaceContainerHighest,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _setConfigs.removeAt(index);
      _renumberSets();
    });
  }

  void _applySetToAll(int sourceIndex) {
    final sourceSet = _setConfigs[sourceIndex];
    setState(() {
      for (int i = 0; i < _setConfigs.length; i++) {
        _setConfigs[i] = _setConfigs[i].copyWith(
          reps: sourceSet.reps,
          weightKg: sourceSet.weightKg,
        );
      }
    });

    final weightStr = sourceSet.weightKg % 1 == 0
        ? '${sourceSet.weightKg.toInt()}'
        : sourceSet.weightKg.toStringAsFixed(1);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied Set ${sourceIndex + 1} (${sourceSet.reps} reps @ ${weightStr}kg) to all ${_setConfigs.length} sets.',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: ValimaiColors.primaryContainer,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateSetReps(int index, int delta) {
    setState(() {
      final current = _setConfigs[index].reps;
      final updated = (current + delta).clamp(1, 100);
      _setConfigs[index] = _setConfigs[index].copyWith(reps: updated);
    });
  }

  void _updateSetWeight(int index, double delta) {
    setState(() {
      final current = _setConfigs[index].weightKg;
      final updated = (current + delta).clamp(0.0, 500.0);
      _setConfigs[index] = _setConfigs[index].copyWith(weightKg: updated);
    });
  }

  Future<void> _showDirectEditDialog({
    required String title,
    required String initialValue,
    required bool isDecimal,
    required ValueChanged<double> onSubmitted,
  }) async {
    final controller = TextEditingController(text: initialValue);
    try {
      await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: ValimaiColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: ValimaiColors.cardBorder, width: 1),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: ValimaiColors.onSurface,
              ),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
              inputFormatters: [
                if (isDecimal)
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                else
                  FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ValimaiColors.onSurface,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: ValimaiColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ValimaiColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: ValimaiColors.primaryContainer,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  final val = double.tryParse(text);
                  if (val != null) {
                    onSubmitted(val);
                  }
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ValimaiColors.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'CONFIRM',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  void _saveAndReturn() {
    if (_setConfigs.isEmpty) {
      _setConfigs = [
        const ExerciseSetConfig(setNumber: 1, reps: 10, weightKg: 20.0),
      ];
    }

    final updatedExercise = widget.workoutExercise.copyWith(
      setConfigs: _setConfigs,
      sets: _setConfigs.length,
      reps: _setConfigs.first.reps,
      weightKg: _setConfigs.first.weightKg,
    );

    Navigator.of(context).pop(updatedExercise);
  }

  @override
  Widget build(BuildContext context) {
    final primaryMuscle =
        _metadata?.primaryMuscleGroup ?? widget.workoutExercise.targetMuscle;
    final equipment =
        _metadata?.equipment ??
        widget.workoutExercise.equipment ??
        EquipmentTypes.barbell;
    final secondaryMuscles =
        _metadata?.secondaryMuscleGroups ??
        widget.workoutExercise.secondaryMuscles;

    return Scaffold(
      backgroundColor: ValimaiColors.background,
      appBar: AppBar(
        backgroundColor: ValimaiColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ValimaiColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'EXERCISE CONFIGURATION',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: ValimaiColors.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveAndReturn,
            child: const Text(
              'DONE',
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
            // EXERCISE OVERVIEW & ATHLETIC HERO CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ValimaiColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ValimaiColors.cardBorder, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Athletic icon thumbnail
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: ValimaiColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ValimaiColors.primaryContainer.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        MuscleGroupCategories.getIcon(primaryMuscle),
                        color: ValimaiColors.primaryContainer,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workoutExercise.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: ValimaiColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            // Primary Muscle Badge
                            _buildInfoChip(
                              label: primaryMuscle.toUpperCase(),
                              isAccent: true,
                            ),
                            // Equipment Badge
                            _buildInfoChip(
                              label: equipment.toUpperCase(),
                              isAccent: false,
                            ),
                            // Secondary Muscles
                            for (final sec in secondaryMuscles)
                              _buildInfoChip(
                                label: sec.toUpperCase(),
                                isAccent: false,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SETS SECTION HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'INDIVIDUAL SETS CONFIGURATION',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: ValimaiColors.secondary,
                  ),
                ),
                Text(
                  '${_setConfigs.length} ${_setConfigs.length == 1 ? "Set" : "Sets"} Configured',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // LIST OF INDIVIDUAL SET CARDS
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _setConfigs.length,
              itemBuilder: (context, index) {
                final set = _setConfigs[index];
                return _buildSetCard(index, set);
              },
            ),

            const SizedBox(height: 12),

            // ADD SET BUTTON
            InkWell(
              onTap: _addSet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ValimaiColors.primaryContainer.withOpacity(0.4),
                    style: BorderStyle.solid,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: ValimaiColors.primaryContainer,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ADD SET',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: ValimaiColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // PROMINENT SAVE CONFIGURATION BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveAndReturn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ValimaiColors.primaryContainer,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'SAVE EXERCISE CONFIGURATION',
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

  Widget _buildSetCard(int index, ExerciseSetConfig set) {
    final weightStr = set.weightKg % 1 == 0
        ? '${set.weightKg.toInt()}'
        : set.weightKg.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ValimaiColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          // Card Header: Set Number, Apply to All, Delete
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ValimaiColors.primaryContainer.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SET ${index + 1}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: ValimaiColors.primaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              // Apply to All Button
              InkWell(
                onTap: () => _applySetToAll(index),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.copy_all,
                        size: 13,
                        color: ValimaiColors.secondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Apply to All',
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
              const SizedBox(width: 8),
              // Delete Button
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: _setConfigs.length > 1
                      ? ValimaiColors.secondary
                      : ValimaiColors.secondary.withOpacity(0.3),
                ),
                onPressed: _setConfigs.length > 1
                    ? () => _removeSet(index)
                    : null,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                tooltip: _setConfigs.length > 1
                    ? 'Delete Set'
                    : 'Minimum 1 set required',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: ValimaiColors.cardBorder, height: 1),
          const SizedBox(height: 12),

          // Steppers Row: REPS & WEIGHT
          Row(
            children: [
              // REPS CONTROL
              Expanded(
                child: _buildMetricControlTile(
                  label: 'REPS',
                  value: '${set.reps}',
                  onDecrement: () => _updateSetReps(index, -1),
                  onIncrement: () => _updateSetReps(index, 1),
                  onTapValue: () {
                    _showDirectEditDialog(
                      title: 'Edit Set ${index + 1} Reps',
                      initialValue: '${set.reps}',
                      isDecimal: false,
                      onSubmitted: (val) {
                        setState(() {
                          _setConfigs[index] = _setConfigs[index].copyWith(
                            reps: val.toInt().clamp(1, 100),
                          );
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // WEIGHT CONTROL
              Expanded(
                child: _buildMetricControlTile(
                  label: 'WEIGHT (KG)',
                  value: '$weightStr kg',
                  onDecrement: () => _updateSetWeight(index, -2.5),
                  onIncrement: () => _updateSetWeight(index, 2.5),
                  onTapValue: () {
                    _showDirectEditDialog(
                      title: 'Edit Set ${index + 1} Weight (kg)',
                      initialValue: weightStr,
                      isDecimal: true,
                      onSubmitted: (val) {
                        setState(() {
                          _setConfigs[index] = _setConfigs[index].copyWith(
                            weightKg: val.clamp(0.0, 500.0),
                          );
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricControlTile({
    required String label,
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required VoidCallback onTapValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: ValimaiColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepperButton(icon: Icons.remove, onTap: onDecrement),
              GestureDetector(
                onTap: onTapValue,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerHigh.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                ),
              ),
              _buildStepperButton(icon: Icons.add, onTap: onIncrement),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Icon(icon, size: 14, color: ValimaiColors.onSurface),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required String label, required bool isAccent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAccent
            ? ValimaiColors.primaryContainer.withOpacity(0.14)
            : ValimaiColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: isAccent
            ? Border.all(
                color: ValimaiColors.primaryContainer.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: isAccent
              ? ValimaiColors.primaryContainer
              : ValimaiColors.secondary,
        ),
      ),
    );
  }
}
