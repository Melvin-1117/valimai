import 'package:flutter/material.dart';
import '../models/weekly_schedule.dart';
import '../models/workout.dart';
import '../services/daily_workout_controller.dart';
import '../services/routine_controller.dart';
import '../services/workout_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/valimai_app_bar.dart';
import 'active_workout_screen.dart';
import 'daily_workout_selection_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final VoidCallback? onStartTodaySession;

  const ScheduleScreen({super.key, this.onStartTodaySession});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedView = 0; // 0: WEEK, 1: MONTH, 2: MESO
  final List<String> _views = ['WEEK', 'MONTH', 'MESO'];

  void _showWeekdayAssignmentSheet(BuildContext context, int weekday, [DateTime? forDate]) {
    final activeRoutines = RoutineController.instance.activeRoutines;
    final currentAssignment = WorkoutController.instance.getWeeklyAssignment(weekday);

    showModalBottomSheet(
      context: context,
      backgroundColor: ValimaiColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ValimaiColors.secondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  forDate != null
                      ? 'SCHEDULE // ${WeeklyDayAssignment.weekdayName(weekday).toUpperCase()}'
                      : 'WEEKLY ASSIGNMENT // ${WeeklyDayAssignment.weekdayName(weekday).toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  forDate != null
                      ? 'Override for this date or update recurring schedule for all ${WeeklyDayAssignment.weekdayName(weekday)}s.'
                      : 'Assign a reusable routine or rest day to all ${WeeklyDayAssignment.weekdayName(weekday)}s.',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: ValimaiColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SELECT REUSABLE ROUTINE',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: ValimaiColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.38,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: activeRoutines.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final routine = activeRoutines[index];
                      final isCurrent = currentAssignment.isWorkout &&
                          currentAssignment.routineId == routine.id;

                      return InkWell(
                        onTap: () async {
                          await WorkoutController.instance
                              .assignRoutineToWeekday(weekday, routine.id);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? ValimaiColors.primaryContainer.withOpacity(0.15)
                                : ValimaiColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent
                                  ? ValimaiColors.primaryContainer
                                  : ValimaiColors.cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: ValimaiColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + (routine.rotationOrder % 26)),
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: ValimaiColors.onSurface,
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
                                      routine.name,
                                      style: const TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: ValimaiColors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${routine.totalExercises} exercises • ${routine.totalSets} sets',
                                      style: const TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 11,
                                        color: ValimaiColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                const Icon(
                                  Icons.check_circle,
                                  color: ValimaiColors.primaryContainer,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Mark as Rest Day
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ValimaiColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: ValimaiColors.secondary,
                      size: 18,
                    ),
                  ),
                  title: const Text(
                    'Mark as Rest Day',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                  subtitle: const Text(
                    'Designate this weekday as a scheduled recovery day',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                  onTap: () async {
                    await WorkoutController.instance.setWeekdayAsRest(weekday);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                ),
                // Remove Assignment
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ValimaiColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.clear,
                      color: ValimaiColors.secondary,
                      size: 18,
                    ),
                  ),
                  title: const Text(
                    'Remove Assignment (Unassigned)',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                  subtitle: const Text(
                    'Fallback to automatic rotation or unassigned state',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                  onTap: () async {
                    await WorkoutController.instance.removeWeekdayAssignment(weekday);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWeeklyPlanDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ValimaiColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: WorkoutController.instance,
          builder: (context, _) {
            final controller = WorkoutController.instance;
            return SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ValimaiColors.secondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'WEEKLY RECURRING SCHEDULE',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ValimaiColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Routines assigned here repeat each week without duplicating templates.',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(7, (i) {
                      final weekday = i + 1;
                      final assignment = controller.getWeeklyAssignment(weekday);
                      final dayName = WeeklyDayAssignment.weekdayName(weekday);

                      String title = 'Unassigned';
                      Color titleColor = ValimaiColors.secondary;
                      if (assignment.isRest) {
                        title = 'Rest & Recovery Day';
                        titleColor = ValimaiColors.onSurfaceVariant;
                      } else if (assignment.isWorkout && assignment.routineId != null) {
                        final routine = RoutineController.instance
                            .getRoutineById(assignment.routineId!);
                        title = routine?.name ?? assignment.routineId!;
                        titleColor = ValimaiColors.onSurface;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: ValimaiColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ValimaiColors.cardBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dayName.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: ValimaiColors.secondary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                _showWeekdayAssignmentSheet(ctx, weekday);
                              },
                              child: const Text(
                                'ASSIGN',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: ValimaiColors.primaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ValimaiAppBar(
        title: 'Schedule',
        showSearch: true,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          WorkoutController.instance,
          RoutineController.instance,
          DailyWorkoutController.instance,
        ]),
        builder: (context, _) {
          final controller = WorkoutController.instance;
          final weekDays = controller.daysOfViewingWeek;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          const months = [
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
            'December'
          ];
          final monthHeader =
              '${months[controller.viewingWeekStart.month]} ${controller.viewingWeekStart.year}';

          final selectedDate = controller.selectedDate;
          final schedule = controller.getDaySchedule(selectedDate);
          final workout = controller.getWorkoutForDate(selectedDate);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Header & Granularity Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildIconButton(
                            Icons.chevron_left, () => controller.previousWeek()),
                        const SizedBox(width: 8),
                        Text(
                          monthHeader,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ValimaiColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildIconButton(
                            Icons.chevron_right, () => controller.nextWeek()),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: List.generate(_views.length, (index) {
                          final isSelected = _selectedView == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedView = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ValimaiColors.primaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _views[index],
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: isSelected
                                      ? Colors.white
                                      : ValimaiColors.secondary,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Mesocycle Progress Strip
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ValimaiColors.cardBorder, width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: ValimaiColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'HYPERTROPHY MESO · CURRENT CYCLE',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: ValimaiColors.primaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'High Volume Microcycle',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              color: ValimaiColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: ValimaiColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.78,
                          child: Container(
                            decoration: BoxDecoration(
                              color: ValimaiColors.primaryContainer,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Weekday: ${WeeklyDayAssignment.weekdayName(selectedDate.weekday)}',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              color: ValimaiColors.secondary,
                            ),
                          ),
                          Text(
                            schedule.isCompleted
                                ? 'Completed'
                                : schedule.type == ScheduledDayType.rest
                                    ? 'Rest Day'
                                    : 'Scheduled Session',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ValimaiColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Weekly Timeline Reel
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MICROCYCLE (${months[weekDays.first.month].substring(0, 3).toUpperCase()} ${weekDays.first.day} – ${weekDays.last.day})',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                    Text(
                      '${weekDays.where((d) => controller.getDaySchedule(d).isCompleted).length} / 7 Completed',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ValimaiColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final dayDate = weekDays[index];
                    final daySchedule = controller.getDaySchedule(dayDate);
                    final isDayToday = dayDate.year == today.year &&
                        dayDate.month == today.month &&
                        dayDate.day == today.day;
                    final isSelected = dayDate.year == selectedDate.year &&
                        dayDate.month == selectedDate.month &&
                        dayDate.day == selectedDate.day;

                    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

                    return _buildTimelineDayItem(
                      index: index,
                      date: dayDate,
                      dayLabel: dayLabels[index],
                      dayNum: dayDate.day.toString(),
                      isCompleted: daySchedule.isCompleted,
                      isRest: daySchedule.type == ScheduledDayType.rest,
                      isToday: isDayToday,
                      isSelected: isSelected,
                      hasWorkout: daySchedule.type == ScheduledDayType.workout,
                      onTap: () {
                        controller.selectDate(dayDate);
                      },
                    );
                  }),
                ),
                const SizedBox(height: 22),

                // Scheduled Sessions Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SCHEDULED SESSION',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showWeeklyPlanDialog(context),
                      child: const Text(
                        'MANAGE WEEKLY PLAN',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: ValimaiColors.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Card for currently selected day
                _buildEffectiveSessionCard(
                  context,
                  date: selectedDate,
                  schedule: schedule,
                  workout: workout,
                ),
                const SizedBox(height: 24),

                // Schedule Modifiers (Bento Toolbar)
                const Text(
                  'SCHEDULE MODIFIERS',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: ValimaiColors.secondary,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showWeeklyPlanDialog(context),
                        borderRadius: BorderRadius.circular(12),
                        child: _buildModifierCard(
                          icon: Icons.edit_calendar,
                          title: 'Weekly Plan',
                          subtitle: 'Assign routines',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DailyWorkoutSelectionScreen(isModal: true),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: _buildModifierCard(
                          icon: Icons.sync_alt,
                          title: 'Daily Override',
                          subtitle: 'Select for today',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                InkWell(
                  onTap: () async {
                    await controller.setDayType(selectedDate, ScheduledDayType.rest);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: _buildUnscheduledRestCard(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineDayItem({
    required int index,
    required DateTime date,
    required String dayLabel,
    required String dayNum,
    required bool isCompleted,
    required bool isRest,
    required bool isToday,
    required bool isSelected,
    required bool hasWorkout,
    required VoidCallback onTap,
  }) {
    if (isToday) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: ValimaiColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40FF5352),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                dayLabel,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dayNum,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check
                      : isRest
                          ? Icons.nightlight_round
                          : Icons.bolt,
                  size: 10,
                  color: ValimaiColors.primaryContainer,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ValimaiColors.surfaceContainerHighest
              : ValimaiColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: ValimaiColors.primaryContainer, width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            Text(
              dayLabel,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ValimaiColors.secondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dayNum,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ValimaiColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            if (isCompleted)
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: ValimaiColors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 10,
                  color: ValimaiColors.primaryContainer,
                ),
              )
            else if (isRest)
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: ValimaiColors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.nightlight_round,
                  size: 9,
                  color: ValimaiColors.secondary,
                ),
              )
            else if (hasWorkout)
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: ValimaiColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectiveSessionCard(
    BuildContext context, {
    required DateTime date,
    required DaySchedule schedule,
    required Workout? workout,
  }) {
    final dayName = WeeklyDayAssignment.weekdayName(date.weekday);
    const months = ['', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final dateStr = '${dayName.toUpperCase()} · ${months[date.month]} ${date.day}';

    if (schedule.type == ScheduledDayType.rest) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ValimaiColors.cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: ValimaiColors.secondary,
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.nightlight_round, size: 13, color: ValimaiColors.secondary),
                    SizedBox(width: 4),
                    Text(
                      'REST & RECOVERY',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Scheduled Rest Day',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ValimaiColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Complete muscle recovery, neurological down-regulation, and protein synthesis.',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: ValimaiColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _showWeekdayAssignmentSheet(context, date.weekday, date),
                icon: const Icon(Icons.fitness_center, size: 16),
                label: const Text(
                  'ASSIGN WORKOUT ROUTINE',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ValimaiColors.primaryContainer,
                  side: const BorderSide(color: ValimaiColors.primaryContainer),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (workout == null || schedule.type == ScheduledDayType.unassigned) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ValimaiColors.cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateStr,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: ValimaiColors.secondary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No Routine Assigned',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ValimaiColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Assign a routine to this weekday or let the rotation engine suggest a session.',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: ValimaiColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _showWeekdayAssignmentSheet(context, date.weekday, date),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'ASSIGN ROUTINE',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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
    }

    return Container(
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              color: schedule.isCompleted
                  ? const Color(0xFF22C55E)
                  : ValimaiColors.primaryContainer,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 14, top: 14, bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: schedule.isCompleted
                                ? const Color(0xFF22C55E)
                                : ValimaiColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            schedule.isCompleted ? 'COMPLETED' : dateStr,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${workout.estimatedDurationMinutes} MIN LIFT',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: ValimaiColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 18, color: ValimaiColors.secondary),
                      onPressed: () => _showWeekdayAssignmentSheet(context, date.weekday, date),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  workout.name,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Focus: ${workout.targetMuscleGroups}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: ValimaiColors.secondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Metrics grid
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'EST DURATION',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${workout.estimatedDurationMinutes} ',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: ValimaiColors.onSurface,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'MIN',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 10,
                                      color: ValimaiColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: ValimaiColors.cardBorder,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'VOLUME LOAD',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${workout.totalSets} ',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: ValimaiColors.onSurface,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'SETS',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 10,
                                      color: ValimaiColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: ValimaiColors.cardBorder,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'EXERCISES',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${workout.exerciseCount} MOVES',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: ValimaiColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Button row
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (widget.onStartTodaySession != null) {
                              widget.onStartTodaySession!();
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ActiveWorkoutScreen(
                                    workoutTitle: workout.name,
                                    workout: workout,
                                    onFinishWithData: (completedWorkout) {
                                      WorkoutController.instance
                                          .markWorkoutCompleted(
                                        date,
                                        true,
                                        completedWorkout: completedWorkout,
                                      );
                                    },
                                    onFinish: () {
                                      WorkoutController.instance
                                          .markWorkoutCompleted(date, true);
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: Text(
                            schedule.isCompleted ? 'Repeat Session' : 'Start Session',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
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
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showWeekdayAssignmentSheet(context, date.weekday, date),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: ValimaiColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ValimaiColors.cardBorder, width: 1),
                        ),
                        child: const Center(
                          child: Text(
                            'CHANGE',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: ValimaiColors.secondary,
                            ),
                          ),
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

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ValimaiColors.secondary, size: 18),
      ),
    );
  }

  Widget _buildModifierCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ValimaiColors.onSurface, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    color: ValimaiColors.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnscheduledRestCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pause_circle_outline,
                  color: ValimaiColors.onSurface,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insert Unscheduled Rest Day',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                  Text(
                    'Shifts remaining Microcycle sessions forward',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: ValimaiColors.secondary, size: 20),
        ],
      ),
    );
  }
}

