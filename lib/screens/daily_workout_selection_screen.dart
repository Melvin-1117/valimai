import 'package:flutter/material.dart';

import '../models/daily_workout.dart';
import '../models/routine.dart';
import '../services/daily_workout_controller.dart';
import '../services/routine_controller.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class DailyWorkoutSelectionScreen extends StatefulWidget {
  final bool isModal;
  final DateTime? targetDate;

  const DailyWorkoutSelectionScreen({
    super.key,
    this.isModal = false,
    this.targetDate,
  });

  @override
  State<DailyWorkoutSelectionScreen> createState() =>
      _DailyWorkoutSelectionScreenState();
}

class _DailyWorkoutSelectionScreenState
    extends State<DailyWorkoutSelectionScreen> {
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    final now = widget.targetDate ?? DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
  }

  void _finishNavigation() {
    if (widget.isModal && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => const MainShell(),
          transitionsBuilder: (context, animation, secAnim, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  Future<void> _handleChooseSuggested(
    WorkoutRoutine routine,
    bool isScheduled,
  ) async {
    await DailyWorkoutController.instance.selectRoutineForToday(
      routine,
      selectionType: isScheduled
          ? DailySelectionType.scheduled
          : DailySelectionType.suggested,
      date: _today,
    );

    if (!mounted) return;
    _finishNavigation();
  }

  Future<void> _handleChooseRoutine(WorkoutRoutine routine) async {
    await DailyWorkoutController.instance.selectRoutineForToday(
      routine,
      selectionType: DailySelectionType.manual,
      date: _today,
    );

    if (!mounted) return;
    _finishNavigation();
  }

  Future<void> _handleChooseRestDay() async {
    await DailyWorkoutController.instance.selectRestDayForToday(date: _today);

    if (!mounted) return;
    _finishNavigation();
  }

  Future<void> _handleSkipForNow() async {
    await DailyWorkoutController.instance.skipForToday(date: _today);

    if (!mounted) return;
    _finishNavigation();
  }

  String _formatTodayHeader(DateTime date) {
    const weekdays = [
      '',
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    const months = [
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

    return '${weekdays[date.weekday]}, ${months[date.month]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final suggested = DailyWorkoutController.instance.getSuggestedRoutine(
      _today,
    );
    final isScheduled =
        suggested != null &&
        DailyWorkoutController.instance.isScheduledForToday(_today, suggested);

    final allActive = RoutineController.instance.activeRoutines;
    final otherRoutines = allActive
        .where((r) => r.id != suggested?.id)
        .toList();

    return Scaffold(
      backgroundColor: ValimaiColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isModal
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: ValimaiColors.onSurface,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: ValimaiColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.bolt, size: 18, color: Colors.white),
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: _handleSkipForNow,
            child: const Text(
              'Skip for Now',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ValimaiColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ValimaiColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ValimaiColors.cardBorder, width: 1),
              ),
              child: Text(
                _formatTodayHeader(_today),
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: ValimaiColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Heading
            Text(
              DateUtils.isSameDay(_today, DateTime.now())
                  ? 'What are we training today?'
                  : 'What are we training?',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: ValimaiColors.onSurface,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateUtils.isSameDay(_today, DateTime.now())
                  ? 'Calibrate your terminal for today’s session or choose recovery.'
                  : 'Assign a workout session or designate recovery for this day.',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: ValimaiColors.secondary,
              ),
            ),
            const SizedBox(height: 24),

            // 1. SUGGESTED / SCHEDULED WORKOUT CARD
            if (suggested != null) ...[
              _buildSuggestedWorkoutCard(suggested, isScheduled),
              const SizedBox(height: 28),
            ],

            // 1b. EMPTY ROUTINES STATE (when user has not created any routines yet)
            if (suggested == null && otherRoutines.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: ValimaiColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ValimaiColors.cardBorder, width: 1),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ValimaiColors.primaryContainer.withOpacity(
                            0.3,
                          ),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center_outlined,
                          size: 22,
                          color: ValimaiColors.primaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Workout Routines Created',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ValimaiColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Create custom routines in the Workouts tab to assign workouts to days, or choose recovery below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        color: ValimaiColors.secondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 2. OTHER AVAILABLE ROUTINES
            if (otherRoutines.isNotEmpty) ...[
              const Text(
                'OTHER AVAILABLE ROUTINES',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: ValimaiColors.secondary,
                ),
              ),
              const SizedBox(height: 12),
              ...otherRoutines.map(
                (routine) => _buildRoutineOptionCard(routine),
              ),
              const SizedBox(height: 20),
            ],

            // 3. REST DAY CARD
            _buildRestDayOptionCard(),
            const SizedBox(height: 24),

            // 4. SKIP FOR NOW FOOTER
            Center(
              child: TextButton.icon(
                onPressed: _handleSkipForNow,
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: ValimaiColors.secondary,
                ),
                label: const Text(
                  'Skip for now, take me to Home',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ValimaiColors.secondary,
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

  Widget _buildSuggestedWorkoutCard(WorkoutRoutine routine, bool isScheduled) {
    final rotationLetter = String.fromCharCode(
      65 + (routine.rotationOrder % 26),
    );

    return Container(
      decoration: BoxDecoration(
        color: ValimaiColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ValimaiColors.primaryContainer.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22F02D36),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag & Label row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ValimaiColors.primaryContainer.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isScheduled ? Icons.event : Icons.autorenew,
                      size: 13,
                      color: ValimaiColors.primaryContainer,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isScheduled
                          ? 'SCHEDULED FOR TODAY'
                          : 'SUGGESTED WORKOUT // ROTATION',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: ValimaiColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ROUTINE $rotationLetter',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Routine Name
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

          // Target Muscle Groups Badges
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
                    color: ValimaiColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    muscle.toUpperCase(),
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

          // Metrics Grid: Movements, Volume, Est Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol('MOVEMENTS', '${routine.totalExercises} Units'),
                _buildMetricCol('VOLUME', '${routine.totalSets} Sets'),
                _buildMetricCol(
                  'EST. TIME',
                  '~${routine.estimatedDurationMinutes}m',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Prominent Choose Workout button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _handleChooseSuggested(routine, isScheduled),
              icon: const Icon(Icons.check, size: 18),
              label: const Text(
                'CHOOSE WORKOUT',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
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
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineOptionCard(WorkoutRoutine routine) {
    final rotationLetter = String.fromCharCode(
      65 + (routine.rotationOrder % 26),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ValimaiColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          // Routine Tag badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                rotationLetter,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ValimaiColors.primaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.name,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${routine.targetMuscleGroups.join(', ')} • ${routine.totalExercises} Movements • ${routine.totalSets} Sets',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Choose Button
          OutlinedButton(
            onPressed: () => _handleChooseRoutine(routine),
            style: OutlinedButton.styleFrom(
              foregroundColor: ValimaiColors.onSurface,
              side: const BorderSide(color: ValimaiColors.cardBorder),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'SELECT',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestDayOptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.nightlight_round,
                size: 22,
                color: ValimaiColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rest & Recovery Day',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Active tissue repair, sleep, and recovery.',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _handleChooseRestDay,
            style: ElevatedButton.styleFrom(
              backgroundColor: ValimaiColors.surfaceContainerHigh,
              foregroundColor: ValimaiColors.onSurface,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'REST DAY',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value) {
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
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: ValimaiColors.onSurface,
          ),
        ),
      ],
    );
  }
}
