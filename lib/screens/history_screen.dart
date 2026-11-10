import 'package:flutter/material.dart';

import '../models/workout_rotation.dart';
import '../services/workout_history_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/valimai_app_bar.dart';
import 'daily_analytics_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _viewingMonth;
  late DateTime _selectedDate;

  final WorkoutHistoryController _historyController =
      WorkoutHistoryController.instance;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewingMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _historyController.initialize();
  }

  void _previousMonth() {
    setState(() {
      _viewingMonth = DateTime(_viewingMonth.year, _viewingMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewingMonth = DateTime(_viewingMonth.year, _viewingMonth.month + 1, 1);
    });
  }

  void _goToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _viewingMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  String _formatMonthYear(DateTime date) {
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
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatFullDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _onDateTapped(DateTime date) {
    setState(() {
      _selectedDate = date;
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target.isAfter(today)) {
      // Future date - cannot have completed sessions
      return;
    }

    final sessions = _historyController.getSessionsForDate(date);
    if (sessions.isNotEmpty) {
      if (sessions.length == 1) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DailyAnalyticsScreen(session: sessions.first),
          ),
        );
      } else {
        _showMultipleSessionsBottomSheet(date, sessions);
      }
    }
  }

  void _showMultipleSessionsBottomSheet(
    DateTime date,
    List<CompletedWorkoutSession> sessions,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ValimaiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'COMPLETED SESSIONS',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: ValimaiColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatFullDate(date),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ValimaiColors.onSurface,
                          ),
                        ),
                      ],
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
                const SizedBox(height: 16),
                ...sessions.map((sess) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: ValimaiColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ValimaiColors.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: Text(
                        sess.routineName ?? 'Completed Workout',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ValimaiColors.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '${sess.calculatedExercisesCount} Exercises • ${sess.calculatedTotalSets} Sets',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: ValimaiColors.primaryContainer,
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DailyAnalyticsScreen(session: sess),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _historyController,
      builder: (context, _) {
        final completedSessions = _historyController.allSessions;

        return Scaffold(
          backgroundColor: ValimaiColors.background,
          appBar: const ValimaiAppBar(title: 'History', showSearch: false),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section A: Compact Monthly Activity Calendar
                _buildMonthlyCalendarCard(),
                const SizedBox(height: 16),

                // Selected Date Status (displays state for selected date without workout)
                _buildSelectedDateStatus(),
                const SizedBox(height: 24),

                // Section B: Chronological Workout History
                _buildWorkoutHistoryHeader(completedSessions.length),
                const SizedBox(height: 12),

                // Section C / List: Empty State or Sessions List
                if (completedSessions.isEmpty)
                  _buildEmptyState()
                else
                  _buildSessionsList(completedSessions),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyCalendarCard() {
    final now = DateTime.now();
    final isViewingCurrentMonth =
        _viewingMonth.year == now.year && _viewingMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ValimaiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          // Month navigation bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    _formatMonthYear(_viewingMonth),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                  if (!isViewingCurrentMonth) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _goToCurrentMonth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ValimaiColors.primaryContainer.withOpacity(
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: ValimaiColors.primaryContainer,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: ValimaiColors.onSurface,
                    ),
                    onPressed: _previousMonth,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: ValimaiColors.onSurface,
                    ),
                    onPressed: _nextMonth,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Weekday Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeekdayLabel('M'),
              _WeekdayLabel('T'),
              _WeekdayLabel('W'),
              _WeekdayLabel('T'),
              _WeekdayLabel('F'),
              _WeekdayLabel('S'),
              _WeekdayLabel('S'),
            ],
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          _buildCalendarGrid(),
          const SizedBox(height: 14),

          // Legend
          const Divider(height: 1, color: ValimaiColors.cardBorder),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                color: ValimaiColors.primaryContainer,
                label: 'Completed',
                isDot: true,
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                color: ValimaiColors.secondary,
                label: 'Rest Day',
                isDot: true,
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                color: const Color(0xFFE5A93B),
                label: 'Skipped',
                isDot: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isDot,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDot)
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
        else
          Container(
            width: 8,
            height: 2,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: ValimaiColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final daysInMonth = DateTime(
      _viewingMonth.year,
      _viewingMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      _viewingMonth.year,
      _viewingMonth.month,
      1,
    ).weekday; // 1 = Mon

    // Leading padding count (days from previous month to align Monday)
    final leadingSpaces = firstWeekday - 1;
    final totalCells = leadingSpaces + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(totalRows, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNumber = cellIndex - leadingSpaces + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox(width: 36, height: 40);
              }

              final cellDate = DateTime(
                _viewingMonth.year,
                _viewingMonth.month,
                dayNumber,
              );
              final isToday =
                  cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;
              final isSelected =
                  cellDate.year == _selectedDate.year &&
                  cellDate.month == _selectedDate.month &&
                  cellDate.day == _selectedDate.day;
              final isFuture = cellDate.isAfter(today);

              // History states (future dates NEVER show activity)
              final bool hasCompleted =
                  !isFuture &&
                  _historyController.hasCompletedWorkoutOnDate(cellDate);
              final bool isRest =
                  !isFuture &&
                  !hasCompleted &&
                  _historyController.isRestDayOnDate(cellDate);
              final bool isSkipped =
                  !isFuture &&
                  !hasCompleted &&
                  !isRest &&
                  _historyController.isSkippedOnDate(cellDate);

              return GestureDetector(
                onTap: () => _onDateTapped(cellDate),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 36,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ValimaiColors.primaryContainer
                        : (isToday
                              ? ValimaiColors.primaryContainer.withOpacity(0.12)
                              : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: ValimaiColors.primaryContainer.withOpacity(
                              0.5,
                            ),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isFuture
                                    ? ValimaiColors.secondary.withOpacity(0.35)
                                    : ValimaiColors.onSurface),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Indicator Dot / Dash
                      SizedBox(
                        height: 4,
                        child: hasCompleted
                            ? Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : ValimaiColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : (isRest
                                  ? Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.8)
                                            : ValimaiColors.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : (isSkipped
                                        ? Container(
                                            width: 6,
                                            height: 2,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white.withOpacity(
                                                      0.8,
                                                    )
                                                  : const Color(0xFFE5A93B),
                                              borderRadius:
                                                  BorderRadius.circular(1),
                                            ),
                                          )
                                        : null)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildSelectedDateStatus() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = _selectedDate.isAfter(today);
    final hasCompleted =
        !isFuture &&
        _historyController.hasCompletedWorkoutOnDate(_selectedDate);

    // If completed, user will either be navigated on tap or can tap the session card below
    if (hasCompleted) {
      final sessions = _historyController.getSessionsForDate(_selectedDate);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ValimaiColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ValimaiColors.primaryContainer.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: ValimaiColors.primaryContainer,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatFullDate(_selectedDate)}: ${sessions.length} Completed Session${sessions.length > 1 ? "s" : ""}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.onSurface,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                if (sessions.length == 1) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          DailyAnalyticsScreen(session: sessions.first),
                    ),
                  );
                } else {
                  _showMultipleSessionsBottomSheet(_selectedDate, sessions);
                }
              },
              child: const Row(
                children: [
                  Text(
                    'VIEW',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.primaryContainer,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: ValimaiColors.primaryContainer,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isRest =
        !isFuture && _historyController.isRestDayOnDate(_selectedDate);
    final isSkipped =
        !isFuture && _historyController.isSkippedOnDate(_selectedDate);

    String statusText;
    IconData statusIcon;
    Color statusColor;

    if (isFuture) {
      statusText = 'Future date — No workout scheduled or recorded';
      statusIcon = Icons.event_available;
      statusColor = ValimaiColors.secondary;
    } else if (isRest) {
      statusText = 'Rest Day — Scheduled recovery day';
      statusIcon = Icons.nightlight_round;
      statusColor = ValimaiColors.secondary;
    } else if (isSkipped) {
      statusText = 'Skipped Day — Workout skipped';
      statusIcon = Icons.skip_next;
      statusColor = const Color(0xFFE5A93B);
    } else {
      statusText = 'No workout recorded on ${_formatFullDate(_selectedDate)}';
      statusIcon = Icons.info_outline;
      statusColor = ValimaiColors.secondary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ValimaiColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutHistoryHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'WORKOUT HISTORY',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: ValimaiColors.secondary,
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count ${count == 1 ? "SESSION" : "SESSIONS"}',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: ValimaiColors.primaryContainer,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: ValimaiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(
                color: ValimaiColors.primaryContainer.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.fitness_center_outlined,
                size: 26,
                color: ValimaiColors.primaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No workouts recorded yet.',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ValimaiColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your workout journey starts here. Complete your first workout to see your progress.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ValimaiColors.secondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(List<CompletedWorkoutSession> sessions) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(CompletedWorkoutSession session) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DailyAnalyticsScreen(session: session),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ValimaiColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ValimaiColors.cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: ValimaiColors.primaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatFullDate(session.completedAt),
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: ValimaiColors.secondaryLight,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ValimaiColors.primaryContainer.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        size: 11,
                        color: ValimaiColors.primaryContainer,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ValimaiColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Routine Name & Chevron
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.routineName ?? 'Completed Workout',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ValimaiColors.onSurface,
                        ),
                      ),
                      if (session.targetMuscleGroups != null &&
                          session.targetMuscleGroups!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          session.targetMuscleGroups!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ValimaiColors.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: ValimaiColors.secondary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: ValimaiColors.cardBorder),
            const SizedBox(height: 10),

            // Performance Metrics Pills
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildStatPill(
                  icon: Icons.fitness_center,
                  label: '${session.calculatedExercisesCount} Exercises',
                ),
                _buildStatPill(
                  icon: Icons.repeat,
                  label: '${session.calculatedTotalSets} Sets',
                ),
                if (session.calculatedVolumeKg > 0)
                  _buildStatPill(
                    icon: Icons.scale,
                    label: '${session.calculatedVolumeKg.toInt()} kg',
                    highlight: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: highlight
                ? ValimaiColors.primaryContainer
                : ValimaiColors.secondary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? ValimaiColors.primaryContainer
                  : ValimaiColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ValimaiColors.secondary,
          ),
        ),
      ),
    );
  }
}
