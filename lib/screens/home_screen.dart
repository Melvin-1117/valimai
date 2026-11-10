import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../services/daily_workout_controller.dart';
import '../services/routine_controller.dart';
import '../services/workout_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/valimai_app_bar.dart';
import 'active_workout_screen.dart';
import 'daily_workout_selection_screen.dart';
import 'workout_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onStartWorkout;
  final ValueChanged<int>? onNavigateTab;
  final void Function(Workout workout)? onStartWorkoutWithData;

  const HomeScreen({
    super.key,
    this.onStartWorkout,
    this.onNavigateTab,
    this.onStartWorkoutWithData,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure workouts & schedules are loaded
    WorkoutController.instance.initialize();
  }

  void _navigateToActiveWorkout(Workout workout, DateTime date) {
    if (widget.onStartWorkoutWithData != null) {
      widget.onStartWorkoutWithData!(workout);
      return;
    }

    if (widget.onStartWorkout != null) {
      widget.onStartWorkout!();
      return;
    }

    // Direct navigation fallback
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutScreen(
          workoutTitle: workout.name,
          workout: workout,
          onFinishWithData: (completedWorkout) {
            WorkoutController.instance.markWorkoutCompleted(
              date,
              true,
              completedWorkout: completedWorkout,
            );
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(3); // Switch to history
            }
          },
          onFinish: () {
            WorkoutController.instance.markWorkoutCompleted(date, true);
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(3); // Switch to history
            }
          },
        ),
      ),
    );
  }

  Future<void> _navigateToWorkoutEditor(
    BuildContext context,
    DateTime date,
    Workout workout,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutEditorScreen(date: date, workout: workout),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ValimaiColors.background,
      appBar: const ValimaiAppBar(title: 'Home'),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          WorkoutController.instance,
          RoutineController.instance,
          DailyWorkoutController.instance,
        ]),
        builder: (context, _) {
          final controller = WorkoutController.instance;
          final selectedDate = controller.selectedDate;
          final daySchedule = controller.getDaySchedule(selectedDate);
          final workout = controller.getWorkoutForDate(selectedDate);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // SECTION A: WEEKLY CALENDAR (Top of Home)
                // ==========================================
                _buildWeeklyCalendarSection(controller),
                const SizedBox(height: 20),

                // ==========================================
                // SECTION B: TODAY'S WORKOUT
                // ==========================================
                _buildWorkoutSection(
                  context,
                  controller: controller,
                  date: selectedDate,
                  schedule: daySchedule,
                  workout: workout,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // SECTION A: WEEKLY CALENDAR (Split Matrix Track)
  // ==========================================
  Widget _buildWeeklyCalendarSection(WorkoutController controller) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekDays = controller.daysOfViewingWeek;
    final firstDay = weekDays.first;
    final lastDay = weekDays.last;

    final months = [
      '',
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
      'December',
    ];

    final isViewingCurrentWeek =
        today.isAfter(firstDay.subtract(const Duration(days: 1))) &&
        today.isBefore(lastDay.add(const Duration(days: 1)));

    final monthTitle = firstDay.month == lastDay.month
        ? '${months[firstDay.month]} ${firstDay.year}'
        : '${months[firstDay.month]} / ${months[lastDay.month]} ${firstDay.year}';

    final weekRangeSubtitle =
        '${firstDay.day.toString().padLeft(2, '0')} – ${lastDay.day.toString().padLeft(2, '0')} ${months[lastDay.month].substring(0, 3).toUpperCase()}';

    // Calculate weekly microcycle progress in a single pass
    int completedWorkouts = 0;
    int plannedWorkouts = 0;
    for (final d in weekDays) {
      final schedule = controller.getDaySchedule(d);
      if (schedule.isCompleted) completedWorkouts++;
      if (schedule.type == ScheduledDayType.workout) plannedWorkouts++;
    }
    final targetCount = plannedWorkouts;
    final progressFraction = targetCount > 0
        ? (completedWorkouts / targetCount).clamp(0.0, 1.0)
        : 0.0;
    final percentComplete = (progressFraction * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ValimaiColors.surface, // Charcoal #25252B
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Month title, range pill, TODAY button, and navigation chevrons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        monthTitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ValimaiColors.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        weekRangeSubtitle,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (!isViewingCurrentWeek)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => controller.jumpToToday(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ValimaiColors.primaryContainer.withOpacity(
                              0.15,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: ValimaiColors.primaryContainer.withOpacity(
                                0.5,
                              ),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: ValimaiColors.primaryContainer,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Previous Week (<)
                  GestureDetector(
                    onTap: () => controller.previousWeek(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ValimaiColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_left,
                          size: 18,
                          color: ValimaiColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Next Week (>)
                  GestureDetector(
                    onTap: () => controller.nextWeek(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ValimaiColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: ValimaiColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Microcycle Streak & Progress Tracker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.bolt,
                    size: 13,
                    color: ValimaiColors.primaryContainer,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'MICROCYCLE PROGRESS',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
              Text(
                targetCount == 0
                    ? '0 of 0 Planned'
                    : '$completedWorkouts of $targetCount Hit ($percentComplete%)',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: ValimaiColors.primaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Microcycle Progress Bar
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressFraction,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ValimaiColors.primaryContainer, Color(0xFFFF6B6B)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 7-Day Balanced Row Strip with Split Tags
          Row(
            children: weekDays.map((dayDate) {
              final isToday =
                  dayDate.year == today.year &&
                  dayDate.month == today.month &&
                  dayDate.day == today.day;

              final isSelected =
                  dayDate.year == controller.selectedDate.year &&
                  dayDate.month == controller.selectedDate.month &&
                  dayDate.day == controller.selectedDate.day;

              final schedule = controller.getDaySchedule(dayDate);
              final workout = controller.getWorkoutForDate(dayDate);
              final splitTag = _deriveSplitTag(schedule, workout);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildDayItem(
                    date: dayDate,
                    isToday: isToday,
                    isSelected: isSelected,
                    schedule: schedule,
                    splitTag: splitTag,
                    onTap: () => controller.selectDate(dayDate),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _deriveSplitTag(DaySchedule schedule, Workout? workout) {
    if (schedule.type == ScheduledDayType.rest) return 'REST';
    if (workout == null) return 'OFF';

    final nameUpper = workout.name.toUpperCase();
    final musclesUpper = workout.targetMuscleGroups.toUpperCase();

    if (nameUpper.contains('PUSH') || musclesUpper.contains('PUSH'))
      return 'PUSH';
    if (nameUpper.contains('PULL') || musclesUpper.contains('PULL'))
      return 'PULL';
    if (nameUpper.contains('LEG') || musclesUpper.contains('LEG'))
      return 'LEGS';
    if (nameUpper.contains('CHEST') || musclesUpper.contains('CHEST'))
      return 'CHEST';
    if (nameUpper.contains('BACK') || musclesUpper.contains('BACK'))
      return 'BACK';
    if (nameUpper.contains('ARM') ||
        musclesUpper.contains('BICEP') ||
        musclesUpper.contains('TRICEP')) {
      return 'ARMS';
    }
    if (nameUpper.contains('SHOULDER') || musclesUpper.contains('DELT')) {
      return 'DELTS';
    }
    if (nameUpper.contains('UPPER')) return 'UPPER';
    if (nameUpper.contains('LOWER')) return 'LOWER';
    if (nameUpper.contains('CORE') || nameUpper.contains('ABS')) return 'CORE';

    if (workout.targetMuscleGroups.isNotEmpty) {
      final targetTokens = workout.targetMuscleGroups.split(RegExp(r'[,·+]'));
      final firstToken = targetTokens.first.trim().toUpperCase();
      if (firstToken.isNotEmpty && firstToken.length <= 5) {
        return firstToken;
      }
    }

    final match = RegExp(
      r'Workout\s+([A-Za-z0-9]+)',
      caseSensitive: false,
    ).firstMatch(workout.name);
    if (match != null) {
      return match.group(1)!.toUpperCase();
    }

    final words = workout.name.trim().split(RegExp(r'\s+'));
    final first = words.first.toUpperCase();
    return first.length > 5 ? first.substring(0, 5) : first;
  }

  Widget _buildDayItem({
    required DateTime date,
    required bool isToday,
    required bool isSelected,
    required DaySchedule schedule,
    required String splitTag,
    required VoidCallback onTap,
  }) {
    const weekdays = ['', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final dayLabel = weekdays[date.weekday];
    final dayNum = date.day.toString();

    final bool hasWorkout = schedule.type == ScheduledDayType.workout;
    final bool isCompleted = schedule.isCompleted;
    final bool isRest = schedule.type == ScheduledDayType.rest;

    // Selected state: Solid Vibrant Red Hero Pill with Glow
    if (isSelected) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 84,
          decoration: BoxDecoration(
            color: ValimaiColors.primaryContainer, // #F02D36
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66F02D36),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayLabel,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dayNum,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              // Split Tag inside hero pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  splitTag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Status Indicator inside selected pill
              if (isCompleted)
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      size: 9,
                      color: ValimaiColors.primaryContainer,
                    ),
                  ),
                )
              else if (isRest)
                const Icon(
                  Icons.nightlight_round,
                  size: 11,
                  color: Colors.white,
                )
              else if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                )
              else if (hasWorkout)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 12),
            ],
          ),
        ),
      );
    }

    // Unselected state: Sleek Charcoal Card with Split Tag
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 84,
        decoration: BoxDecoration(
          color: isToday
              ? ValimaiColors.primaryContainer.withOpacity(0.10)
              : ValimaiColors.surfaceContainerLow, // Charcoal #1A1A1E
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday
                ? ValimaiColors.primaryContainer.withOpacity(0.85)
                : ValimaiColors.cardBorder,
            width: isToday ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayLabel,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                color: isToday
                    ? ValimaiColors.primaryContainer
                    : ValimaiColors.secondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dayNum,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isToday
                    ? ValimaiColors.primaryContainer
                    : ValimaiColors.onSurface,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            // Split Tag inside normal pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: isToday
                    ? ValimaiColors.primaryContainer.withOpacity(0.18)
                    : isRest
                    ? ValimaiColors.surfaceContainerHigh.withOpacity(0.4)
                    : ValimaiColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                splitTag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: isToday
                      ? ValimaiColors.primaryContainer
                      : isRest
                      ? ValimaiColors.secondary.withOpacity(0.7)
                      : ValimaiColors.primaryContainer,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Status Indicator inside normal pill
            if (isCompleted)
              const Icon(
                Icons.check_circle,
                size: 13,
                color: ValimaiColors.primaryContainer,
              )
            else if (isRest)
              const Icon(
                Icons.nightlight_outlined,
                size: 11,
                color: ValimaiColors.secondary,
              )
            else if (isToday)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: ValimaiColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
              )
            else if (hasWorkout)
              Container(
                width: 4.5,
                height: 4.5,
                decoration: BoxDecoration(
                  color: ValimaiColors.primaryContainer.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION B & C: TODAY'S WORKOUT & MODIFY
  // ==========================================
  Widget _buildWorkoutSection(
    BuildContext context, {
    required WorkoutController controller,
    required DateTime date,
    required DaySchedule schedule,
    required Workout? workout,
  }) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    final weekdays = [
      '',
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
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

    final headerDateStr =
        '${weekdays[date.weekday]}, ${months[date.month]} ${date.day}';

    // SCENARIO 2: REST DAY
    if (schedule.type == ScheduledDayType.rest) {
      return _buildRestDayCard(
        context,
        date: date,
        headerDateStr: headerDateStr,
        isToday: isToday,
      );
    }

    // SCENARIO 3: NO WORKOUT ASSIGNED
    if (schedule.type == ScheduledDayType.unassigned || workout == null) {
      return _buildUnassignedCard(
        context,
        date: date,
        headerDateStr: headerDateStr,
        isToday: isToday,
      );
    }

    // SCENARIO 4: WORKOUT COMPLETED
    if (schedule.isCompleted) {
      return _buildCompletedWorkoutCard(
        context,
        date: date,
        workout: workout,
        headerDateStr: headerDateStr,
        isToday: isToday,
      );
    }

    // SCENARIO 1: WORKOUT ASSIGNED & ACTIVE
    return _buildActiveWorkoutCard(
      context,
      date: date,
      workout: workout,
      headerDateStr: headerDateStr,
      isToday: isToday,
    );
  }

  // ----------------------------------------------------
  // Scenario 1: Active Assigned Workout Card
  // ----------------------------------------------------
  Widget _buildActiveWorkoutCard(
    BuildContext context, {
    required DateTime date,
    required Workout workout,
    required String headerDateStr,
    required bool isToday,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ValimaiColors.surface, // Charcoal #25252B
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isToday
                      ? ValimaiColors.primaryContainer
                      : ValimaiColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      isToday ? Icons.bolt : Icons.calendar_today,
                      size: 13,
                      color: isToday ? Colors.white : ValimaiColors.secondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isToday ? "TODAY'S WORKOUT" : "ASSIGNED SESSION",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isToday ? Colors.white : ValimaiColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Text(
                  headerDateStr,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.secondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Workout Name
          Text(
            workout.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ValimaiColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),

          // Target Muscle Groups
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.adjust,
                  size: 13,
                  color: ValimaiColors.primaryContainer,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  workout.targetMuscleGroups,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: ValimaiColors.secondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metrics Tiles: Exercises, Planned Sets, Estimated Duration
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'EXERCISES',
                  '${workout.exerciseCount}',
                  'Movements',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'VOLUME',
                  '${workout.totalSets}',
                  'Planned Sets',
                  isAccent: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'DURATION',
                  '~${workout.estimatedDurationMinutes}m',
                  'Est. Time',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Exercises Preview List
          const Text(
            'EXERCISES IN PROTOCOL',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: ValimaiColors.secondary,
            ),
          ),
          const SizedBox(height: 8),

          Column(
            children: workout.exercises.take(4).map((ex) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.name,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ValimaiColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            ex.weightKg > 0
                                ? '${ex.targetMuscle} • ${ex.weightKg} kg × ${ex.reps}'
                                : '${ex.targetMuscle} • Bodyweight × ${ex.reps}',
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${ex.sets} SETS',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ValimaiColors.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          if (workout.exercises.length > 4) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(
                '+ ${workout.exercises.length - 4} more exercises',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: ValimaiColors.secondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Prominent Red Start Today's Workout Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _navigateToActiveWorkout(workout, date),
              style: ElevatedButton.styleFrom(
                backgroundColor: ValimaiColors.primaryContainer, // #F02D36
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    isToday ? "START TODAY'S WORKOUT" : "START SESSION",
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // SECTION C: MODIFY WORKOUT BUTTON
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _navigateToWorkoutEditor(context, date, workout),
              icon: const Icon(
                Icons.tune,
                size: 16,
                color: ValimaiColors.onSurface,
              ),
              label: const Text(
                'MODIFY WORKOUT',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: ValimaiColors.onSurface,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: ValimaiColors.surfaceContainerLow,
                side: const BorderSide(
                  color: ValimaiColors.cardBorder,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (isToday) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DailyWorkoutSelectionScreen(
                        isModal: true,
                        targetDate: date,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.sync_alt,
                  size: 14,
                  color: ValimaiColors.secondary,
                ),
                label: const Text(
                  "CHANGE TODAY'S SELECTION",
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Scenario 2: Clean Rest Day Card
  // ----------------------------------------------------
  Widget _buildRestDayCard(
    BuildContext context, {
    required DateTime date,
    required String headerDateStr,
    required bool isToday,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ValimaiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.self_improvement,
                      size: 14,
                      color: ValimaiColors.secondary,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'SCHEDULED REST & RECOVERY',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                headerDateStr,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ValimaiColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Center(
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: ValimaiColors.surfaceContainerLow,
                shape: BoxShape.circle,
                border: Border.all(color: ValimaiColors.cardBorder, width: 1),
              ),
              child: const Icon(
                Icons.nightlight_round,
                color: ValimaiColors.primaryContainer,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Center(
            child: Text(
              'Active Recovery Day',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ValimaiColors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Muscles grow and adapt during rest. Prioritize sleep, hydration, and nutritional replenishment today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: ValimaiColors.secondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Recovery Targets Row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'SLEEP TARGET',
                  '8.5 hrs',
                  'Deep Restoration',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'HYDRATION',
                  '3.5 L',
                  'Electrolyte Balance',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action: Swap to workout day if athlete wants to train
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DailyWorkoutSelectionScreen(
                      isModal: true,
                      targetDate: date,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.fitness_center,
                size: 16,
                color: ValimaiColors.primaryContainer,
              ),
              label: const Text(
                'ASSIGN A WORKOUT TO THIS DAY',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: ValimaiColors.onSurface,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: ValimaiColors.surfaceContainerLow,
                side: const BorderSide(
                  color: ValimaiColors.cardBorder,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (isToday) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DailyWorkoutSelectionScreen(
                        isModal: true,
                        targetDate: date,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.sync_alt,
                  size: 14,
                  color: ValimaiColors.secondary,
                ),
                label: const Text(
                  "CHANGE TODAY'S SELECTION",
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Scenario 3: Unassigned Day Card
  // ----------------------------------------------------
  Widget _buildUnassignedCard(
    BuildContext context, {
    required DateTime date,
    required String headerDateStr,
    required bool isToday,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ValimaiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_outlined,
              color: ValimaiColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Workout Scheduled',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ValimaiColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No training protocol is currently assigned for $headerDateStr.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: ValimaiColors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DailyWorkoutSelectionScreen(
                      isModal: true,
                      targetDate: date,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'ASSIGN WORKOUT',
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
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Scenario 4: Completed Workout Card
  // ----------------------------------------------------
  Widget _buildCompletedWorkoutCard(
    BuildContext context, {
    required DateTime date,
    required Workout workout,
    required String headerDateStr,
    required bool isToday,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ValimaiColors.primaryContainer.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: ValimaiColors.primaryContainer.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 13,
                      color: ValimaiColors.primaryContainer,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'WORKOUT COMPLETED',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: ValimaiColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                headerDateStr,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ValimaiColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            workout.name,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ValimaiColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            workout.targetMuscleGroups,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: ValimaiColors.secondary,
            ),
          ),
          const SizedBox(height: 14),

          // Completion Summary Tiles
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'SETS LOGGED',
                  '${workout.totalSets}',
                  'All Complete',
                  isAccent: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'EXERCISES',
                  '${workout.exerciseCount}',
                  'Movements',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'TIME LOGGED',
                  '${workout.estimatedDurationMinutes}m',
                  'Paced Load',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action 1: Repeat Workout
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToActiveWorkout(workout, date),
              icon: const Icon(Icons.replay, size: 18),
              label: const Text(
                'REPEAT SESSION',
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
          const SizedBox(height: 8),

          // Action 2: Section C Modify Workout
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () => _navigateToWorkoutEditor(context, date, workout),
              icon: const Icon(
                Icons.tune,
                size: 15,
                color: ValimaiColors.onSurface,
              ),
              label: const Text(
                'MODIFY WORKOUT',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: ValimaiColors.onSurface,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: ValimaiColors.surfaceContainerLow,
                side: const BorderSide(
                  color: ValimaiColors.cardBorder,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (isToday) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DailyWorkoutSelectionScreen(
                        isModal: true,
                        targetDate: date,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.sync_alt,
                  size: 14,
                  color: ValimaiColors.secondary,
                ),
                label: const Text(
                  "CHANGE TODAY'S SELECTION",
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    String sub, {
    bool isAccent = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: ValimaiColors.secondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isAccent
                  ? ValimaiColors.primaryContainer
                  : ValimaiColors.onSurface,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10,
              color: ValimaiColors.secondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
