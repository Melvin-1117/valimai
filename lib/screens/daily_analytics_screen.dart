import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/workout_rotation.dart';
import '../theme/app_theme.dart';

/// Read-only screen presenting comprehensive performance metrics for a completed workout session.
class DailyAnalyticsScreen extends StatelessWidget {
  final CompletedWorkoutSession session;

  const DailyAnalyticsScreen({
    super.key,
    required this.session,
  });

  String _formatWeekday(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[date.weekday - 1];
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${_formatWeekday(date)}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<String> _extractMuscleGroups() {
    final Set<String> muscles = {};
    if (session.targetMuscleGroups != null &&
        session.targetMuscleGroups!.trim().isNotEmpty) {
      final parts = session.targetMuscleGroups!
          .split(RegExp(r'[,•/+]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      muscles.addAll(parts);
    }

    if (session.workoutSnapshot != null) {
      for (final ex in session.workoutSnapshot!.exercises) {
        if (ex.targetMuscle.isNotEmpty && ex.targetMuscle != 'General') {
          muscles.add(ex.targetMuscle.trim());
        }
        for (final sec in ex.secondaryMuscles) {
          if (sec.trim().isNotEmpty) {
            muscles.add(sec.trim());
          }
        }
      }
    }

    if (muscles.isEmpty) {
      return ['Full Body'];
    }
    return muscles.toList();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = session.workoutSnapshot?.exercises ?? [];
    final muscleGroups = _extractMuscleGroups();

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
          'DAILY ANALYTICS',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: ValimaiColors.onSurface,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ValimaiColors.primaryContainer.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ValimaiColors.primaryContainer.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: ValimaiColors.primaryContainer,
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  'COMPLETED',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ValimaiColors.primaryContainer,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            _buildHeaderCard(),
            const SizedBox(height: 20),

            // Section A: Workout Summary Cards (2x2 Grid)
            _buildSummarySection(),
            const SizedBox(height: 24),

            // Section B: Exercise Performance List
            _buildExercisePerformanceSection(exercises),
            const SizedBox(height: 24),

            // Section C: Muscle Groups Trained
            _buildMuscleGroupsSection(muscleGroups),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ValimaiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: ValimaiColors.primaryContainer,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatFullDate(session.completedAt),
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: ValimaiColors.secondaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            session.routineName ?? 'Completed Workout',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ValimaiColors.onSurface,
            ),
          ),
          if (session.targetMuscleGroups != null &&
              session.targetMuscleGroups!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  size: 14,
                  color: ValimaiColors.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    session.targetMuscleGroups!,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final exercisesCount = session.calculatedExercisesCount;
    final totalSets = session.calculatedTotalSets;
    final totalReps = session.calculatedTotalReps;
    final volumeKg = session.calculatedVolumeKg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WORKOUT SUMMARY',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: ValimaiColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'EXERCISES',
                value: '$exercisesCount',
                subtitle: 'Performed',
                icon: Icons.fitness_center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'TOTAL SETS',
                value: '$totalSets',
                subtitle: 'Completed',
                icon: Icons.repeat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'TOTAL REPS',
                value: '$totalReps',
                subtitle: 'Repetitions',
                icon: Icons.format_list_numbered,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'VOLUME',
                value: '${volumeKg.toInt()} kg',
                subtitle: 'Total Weight',
                icon: Icons.scale,
                highlightValue: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    bool highlightValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ValimaiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlightValue
              ? ValimaiColors.primaryContainer.withOpacity(0.3)
              : ValimaiColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: ValimaiColors.secondary,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: highlightValue
                    ? ValimaiColors.primaryContainer
                    : ValimaiColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: highlightValue
                  ? ValimaiColors.primaryContainer
                  : ValimaiColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ValimaiColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisePerformanceSection(List<WorkoutExercise> exercises) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'EXERCISE PERFORMANCE',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: ValimaiColors.secondary,
              ),
            ),
            Text(
              '${exercises.length} EXERCISES',
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
        const SizedBox(height: 12),
        if (exercises.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ValimaiColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ValimaiColors.cardBorder, width: 1),
            ),
            child: const Center(
              child: Text(
                'No exercise breakdown available for this session.',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: ValimaiColors.secondary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exercises.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ex = exercises[index];
              return _buildExerciseCard(index + 1, ex);
            },
          ),
      ],
    );
  }

  Widget _buildExerciseCard(int order, WorkoutExercise exercise) {
    final sets = exercise.effectiveSetConfigs;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ValimaiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise title & order
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$order',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.primaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ValimaiColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise.targetMuscle,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${sets.length} ${sets.length == 1 ? "SET" : "SETS"}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: ValimaiColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: ValimaiColors.cardBorder),
          const SizedBox(height: 12),

          // Set breakdown list
          Column(
            children: sets.map((set) {
              final weightText = set.weightKg > 0
                  ? '${set.weightKg % 1 == 0 ? set.weightKg.toInt() : set.weightKg} kg'
                  : 'Bodyweight';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'S${set.setNumber}',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Set ${set.setNumber} — $weightText × ${set.reps} reps',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ValimaiColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: ValimaiColors.primaryContainer.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check,
                          size: 13,
                          color: ValimaiColors.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleGroupsSection(List<String> muscleGroups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MUSCLE GROUPS TRAINED',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: ValimaiColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: muscleGroups.map((group) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: ValimaiColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ValimaiColors.primaryContainer.withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: ValimaiColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
