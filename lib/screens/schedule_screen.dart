import 'package:flutter/material.dart';

import '../models/daily_workout.dart';
import '../models/routine.dart';
import '../models/workout.dart';
import '../services/daily_workout_controller.dart';
import '../services/routine_controller.dart';
import '../services/workout_controller.dart';
import '../services/workout_history_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/valimai_app_bar.dart';

/// Valimai Schedule Page – Individual Date Workout & Rest Scheduling
class ScheduleScreen extends StatefulWidget {
  final VoidCallback? onStartTodaySession;

  const ScheduleScreen({super.key, this.onStartTodaySession});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _viewingMonth;
  late DateTime _selectedDate;

  // Pending change held in memory until explicit user Save
  ScheduledDayType? _pendingType;
  String? _pendingRoutineId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewingMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  /// Check whether the selected date is strictly read-only
  bool _isDateEditable(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target.isBefore(today)) {
      return false; // Past dates are strictly read-only
    }

    if (target == today) {
      final schedule = WorkoutController.instance.getDaySchedule(today);
      final isCompleted =
          schedule.isCompleted ||
          WorkoutHistoryController.instance
              .getSessionsForDate(today)
              .isNotEmpty;
      return !isCompleted; // Today is editable only if not yet completed
    }

    return true; // Future dates are fully editable
  }

  /// Whether today's session is locked due to completion
  bool _isTodayCompleted(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target != today) return false;

    final schedule = WorkoutController.instance.getDaySchedule(today);
    return schedule.isCompleted ||
        WorkoutHistoryController.instance.getSessionsForDate(today).isNotEmpty;
  }

  /// Retrieve the current persisted assignment for a specific date
  DaySchedule _getSavedSchedule(DateTime date) {
    final norm = DateTime(date.year, date.month, date.day);
    final key = DaySchedule.dateKey(norm);

    if (WorkoutController.instance.schedules.containsKey(key)) {
      final s = WorkoutController.instance.schedules[key]!;
      if (s.workoutId != null && s.customWorkout == null) {
        final r = RoutineController.instance.getRoutineById(s.workoutId!);
        return s.copyWith(customWorkout: r?.toWorkout());
      }
      return s;
    }

    // Check if recorded in DailyWorkoutController
    final daily = DailyWorkoutController.instance.getDailyWorkoutForDate(norm);
    if (daily != null) {
      if (daily.isRest) {
        return DaySchedule(date: norm, type: ScheduledDayType.rest);
      }
      if (daily.status == DailyWorkoutStatus.completed &&
          daily.selectedRoutineId != null) {
        final r = RoutineController.instance.getRoutineById(
          daily.selectedRoutineId!,
        );
        return DaySchedule(
          date: norm,
          type: ScheduledDayType.workout,
          workoutId: daily.selectedRoutineId,
          customWorkout: r?.toWorkout(),
          isCompleted: true,
          completedAt: daily.completedAt,
        );
      }
      if (daily.hasWorkout && daily.selectedRoutineId != null) {
        final r = RoutineController.instance.getRoutineById(
          daily.selectedRoutineId!,
        );
        return DaySchedule(
          date: norm,
          type: ScheduledDayType.workout,
          workoutId: daily.selectedRoutineId,
          customWorkout: r?.toWorkout(),
        );
      }
    }

    return DaySchedule(date: norm, type: ScheduledDayType.unassigned);
  }

  /// Whether a valid pending change exists for the selected date
  bool get hasPendingChanges {
    if (_pendingType == null) return false;
    final saved = _getSavedSchedule(_selectedDate);

    // If pending matches saved state, there are no uncommitted changes
    if (_pendingType == saved.type && _pendingRoutineId == saved.workoutId) {
      return false;
    }
    return true;
  }

  /// Prompt user to Save, Discard, or Cancel pending changes
  Future<bool> _showUnsavedChangesDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ValimaiColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ValimaiColors.cardBorder),
          ),
          title: const Text(
            'Unsaved Changes',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ValimaiColors.onSurface,
            ),
          ),
          content: Text(
            'You have unsaved changes for ${_formatDateHeader(_selectedDate)}. Would you like to save or discard them?',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              color: ValimaiColors.secondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  color: ValimaiColors.secondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('discard'),
              child: const Text(
                'DISCARD',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop('save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ValimaiColors.primaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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

    if (result == 'save') {
      await _savePendingAssignment();
      return true;
    } else if (result == 'discard') {
      setState(() {
        _pendingType = null;
        _pendingRoutineId = null;
      });
      return true;
    }
    return false; // Cancel
  }

  /// Handle calendar date tapping with unsaved changes safety
  Future<void> _handleDateTapped(DateTime date) async {
    final norm = DateTime(date.year, date.month, date.day);
    if (_selectedDate == norm) return;

    if (hasPendingChanges) {
      final canProceed = await _showUnsavedChangesDialog();
      if (!canProceed) return;
    }

    setState(() {
      _selectedDate = norm;
      _pendingType = null;
      _pendingRoutineId = null;
    });
  }

  /// Month navigation with unsaved changes safety
  Future<void> _previousMonth() async {
    if (hasPendingChanges) {
      final canProceed = await _showUnsavedChangesDialog();
      if (!canProceed) return;
    }

    setState(() {
      _viewingMonth = DateTime(_viewingMonth.year, _viewingMonth.month - 1, 1);
      _pendingType = null;
      _pendingRoutineId = null;

      // Ensure selected day is clamped within valid month length
      final daysInNewMonth = DateTime(
        _viewingMonth.year,
        _viewingMonth.month + 1,
        0,
      ).day;
      final clampedDay = _selectedDate.day.clamp(1, daysInNewMonth);
      _selectedDate = DateTime(
        _viewingMonth.year,
        _viewingMonth.month,
        clampedDay,
      );
    });
  }

  Future<void> _nextMonth() async {
    if (hasPendingChanges) {
      final canProceed = await _showUnsavedChangesDialog();
      if (!canProceed) return;
    }

    setState(() {
      _viewingMonth = DateTime(_viewingMonth.year, _viewingMonth.month + 1, 1);
      _pendingType = null;
      _pendingRoutineId = null;

      final daysInNewMonth = DateTime(
        _viewingMonth.year,
        _viewingMonth.month + 1,
        0,
      ).day;
      final clampedDay = _selectedDate.day.clamp(1, daysInNewMonth);
      _selectedDate = DateTime(
        _viewingMonth.year,
        _viewingMonth.month,
        clampedDay,
      );
    });
  }

  Future<void> _goToCurrentMonth() async {
    if (hasPendingChanges) {
      final canProceed = await _showUnsavedChangesDialog();
      if (!canProceed) return;
    }

    final now = DateTime.now();
    setState(() {
      _viewingMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
      _pendingType = null;
      _pendingRoutineId = null;
    });
  }

  /// Commit pending assignment changes to persistent storage
  Future<void> _savePendingAssignment() async {
    if (!hasPendingChanges || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    bool success = false;
    try {
      if (_pendingType == ScheduledDayType.workout &&
          _pendingRoutineId != null) {
        success = await WorkoutController.instance.assignRoutineToDate(
          _selectedDate,
          _pendingRoutineId!,
        );
      } else if (_pendingType == ScheduledDayType.rest) {
        success = await WorkoutController.instance.setRestDayForDate(
          _selectedDate,
        );
      } else if (_pendingType == ScheduledDayType.unassigned) {
        success = await WorkoutController.instance.clearDateAssignment(
          _selectedDate,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ValimaiColors.surfaceContainerHigh,
            content: Text(
              'Schedule saved for ${_formatDateHeader(_selectedDate)}',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save schedule error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          if (success) {
            _pendingType = null;
            _pendingRoutineId = null;
          }
        });
      }
    }
  }

  /// Display bottom sheet for selecting a Routine or marking Rest Day
  void _openRoutineSelectionSheet(BuildContext context) {
    if (!_isDateEditable(_selectedDate)) return;

    final activeRoutines = RoutineController.instance.activeRoutines;
    final saved = _getSavedSchedule(_selectedDate);
    final effectiveType = _pendingType ?? saved.type;
    final effectiveRoutineId = _pendingType != null
        ? _pendingRoutineId
        : saved.workoutId;

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
                  'ASSIGN WORKOUT // ${_formatShortDate(_selectedDate).toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select a routine or mark this date as a rest day.',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: ValimaiColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Option: REST DAY
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _pendingType = ScheduledDayType.rest;
                        _pendingRoutineId = null;
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        color: effectiveType == ScheduledDayType.rest
                            ? ValimaiColors.primaryContainer.withOpacity(0.12)
                            : ValimaiColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: effectiveType == ScheduledDayType.rest
                              ? ValimaiColors.primaryContainer
                              : ValimaiColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: ValimaiColors.surfaceContainerHigh,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.nightlight_round,
                                size: 18,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Rest Day',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: ValimaiColors.onSurface,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Designate this date for physical recovery & repair',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                    color: ValimaiColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (effectiveType == ScheduledDayType.rest)
                            const Icon(
                              Icons.check_circle,
                              color: ValimaiColors.primaryContainer,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  'AVAILABLE ROUTINES',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: ValimaiColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),

                if (activeRoutines.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ValimaiColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ValimaiColors.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 28,
                          color: ValimaiColors.secondary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No workout routines created yet.',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ValimaiColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Create custom routines in the Workouts tab to assign workouts to days.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            color: ValimaiColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.40,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: activeRoutines.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final routine = activeRoutines[index];
                        final isCurrent =
                            effectiveType == ScheduledDayType.workout &&
                            effectiveRoutineId == routine.id;

                        final muscles = routine.targetMuscleGroups.isNotEmpty
                            ? routine.targetMuscleGroups.join(', ')
                            : 'All Muscle Groups';

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _pendingType = ScheduledDayType.workout;
                                _pendingRoutineId = routine.id;
                              });
                              Navigator.of(ctx).pop();
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? ValimaiColors.primaryContainer
                                          .withOpacity(0.12)
                                    : ValimaiColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrent
                                      ? ValimaiColors.primaryContainer
                                      : ValimaiColors.cardBorder,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? ValimaiColors.primaryContainer
                                          : ValimaiColors.surfaceContainerHigh,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.fitness_center,
                                        size: 16,
                                        color: isCurrent
                                            ? Colors.white
                                            : ValimaiColors.secondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          routine.name,
                                          style: const TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: ValimaiColors.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${routine.exercises.length} Exercises · $muscles',
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
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Mark the selected date for pending clearance
  void _clearSelectedDate() {
    if (!_isDateEditable(_selectedDate)) return;

    setState(() {
      _pendingType = ScheduledDayType.unassigned;
      _pendingRoutineId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasPendingChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (hasPendingChanges) {
          final canProceed = await _showUnsavedChangesDialog();
          if (canProceed && mounted) {
            Navigator.of(context).pop();
          }
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: ValimaiColors.background,
        appBar: const ValimaiAppBar(title: 'Schedule', showSearch: false),
        body: ListenableBuilder(
          listenable: Listenable.merge([
            WorkoutController.instance,
            RoutineController.instance,
            DailyWorkoutController.instance,
          ]),
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION A: Monthly Calendar
                  _buildMonthlyCalendar(),
                  const SizedBox(height: 20),

                  // SECTION B: Selected Date Scheduling Details Panel
                  _buildSelectedDatePanel(),
                  const SizedBox(height: 16),

                  // SECTION C: Explicit Save Action Button
                  _buildSaveButton(),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // SECTION A: MONTHLY CALENDAR
  // ==========================================
  Widget _buildMonthlyCalendar() {
    final now = DateTime.now();
    final isCurrentMonth =
        _viewingMonth.year == now.year && _viewingMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ValimaiColors.surface, // Charcoal #25252B
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          // Month Header & Navigation Chevrons
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
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (!isCurrentMonth) ...[
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
                            0.18,
                          ),
                          borderRadius: BorderRadius.circular(4),
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
                  ],
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _previousMonth,
                    child: Container(
                      width: 32,
                      height: 32,
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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _nextMonth,
                    child: Container(
                      width: 32,
                      height: 32,
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
          const SizedBox(height: 16),

          // Weekday Labels (MON - SUN)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _WeekdayLabel('MON'),
              _WeekdayLabel('TUE'),
              _WeekdayLabel('WED'),
              _WeekdayLabel('THU'),
              _WeekdayLabel('FRI'),
              _WeekdayLabel('SAT'),
              _WeekdayLabel('SUN'),
            ],
          ),
          const SizedBox(height: 10),

          // Monthly Grid of Dates
          _buildMonthGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthGrid() {
    final year = _viewingMonth.year;
    final month = _viewingMonth.month;

    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingSpaces = firstDay.weekday - 1; // Mon = 1 => 0 spaces

    final totalSlots = leadingSpaces + daysInMonth;
    final totalRows = (totalSlots / 7).ceil();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: List.generate(totalRows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (col) {
              final slotIndex = row * 7 + col;
              final dayNumber = slotIndex - leadingSpaces + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 44));
              }

              final cellDate = DateTime(year, month, dayNumber);
              final isToday = cellDate == today;
              final isSelected = cellDate == _selectedDate;
              final isPast = cellDate.isBefore(today);

              // Determine schedule indicator state (including pending preview)
              ScheduledDayType indicatorType;
              if (isSelected && _pendingType != null) {
                indicatorType = _pendingType!;
              } else {
                indicatorType = WorkoutController.instance.getDateScheduleType(
                  cellDate,
                );
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => _handleDateTapped(cellDate),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ValimaiColors
                                .primaryContainer // Red highlight
                          : isToday
                          ? ValimaiColors.surfaceContainerHigh
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? Border.all(
                              color: isSelected
                                  ? Colors
                                        .white // Distinct outline when both today & selected
                                  : ValimaiColors.primaryContainer,
                              width: isSelected ? 2.0 : 1.5,
                            )
                          : isSelected
                          ? Border.all(
                              color: ValimaiColors.primaryContainer,
                              width: 1.5,
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
                            fontSize: 13,
                            fontWeight: (isSelected || isToday)
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                ? Colors.white
                                : isPast
                                ? ValimaiColors.secondary.withOpacity(0.4)
                                : ValimaiColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Indicator dot below date number
                        _buildDateIndicator(
                          type: indicatorType,
                          isSelected: isSelected,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDateIndicator({
    required ScheduledDayType type,
    required bool isSelected,
  }) {
    switch (type) {
      case ScheduledDayType.workout:
        return Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : ValimaiColors.primaryContainer,
            shape: BoxShape.circle,
          ),
        );
      case ScheduledDayType.rest:
        return Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white70 : ValimaiColors.secondary,
            shape: BoxShape.circle,
          ),
        );
      case ScheduledDayType.unassigned:
        return const SizedBox(height: 5);
    }
  }

  // ==========================================
  // SECTION B: SELECTED DATE DETAILS PANEL
  // ==========================================
  Widget _buildSelectedDatePanel() {
    final isEditable = _isDateEditable(_selectedDate);
    final isLockedToday = _isTodayCompleted(_selectedDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = _selectedDate.isBefore(today);

    final saved = _getSavedSchedule(_selectedDate);
    final effectiveType = _pendingType ?? saved.type;
    final effectiveRoutineId = _pendingType != null
        ? _pendingRoutineId
        : saved.workoutId;

    WorkoutRoutine? routine;
    if (effectiveType == ScheduledDayType.workout &&
        effectiveRoutineId != null) {
      routine = RoutineController.instance.getRoutineById(effectiveRoutineId);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ValimaiColors.surface, // Charcoal #25252B
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasPendingChanges
              ? ValimaiColors.primaryContainer.withOpacity(0.6)
              : ValimaiColors.cardBorder,
          width: hasPendingChanges ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Full Date & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _formatDateHeader(_selectedDate),
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: ValimaiColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (hasPendingChanges)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ValimaiColors.primaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ValimaiColors.primaryContainer,
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'PENDING SAVE',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.primaryContainer,
                      letterSpacing: 0.6,
                    ),
                  ),
                )
              else if (isLockedToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'COMPLETED // LOCKED',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.greenAccent,
                      letterSpacing: 0.6,
                    ),
                  ),
                )
              else if (isPast)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PAST // READ ONLY',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.secondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Main State Card
          if (effectiveType == ScheduledDayType.workout) ...[
            _buildWorkoutAssignedState(
              routine: routine,
              routineId: effectiveRoutineId,
              isEditable: isEditable,
            ),
          ] else if (effectiveType == ScheduledDayType.rest) ...[
            _buildRestDayState(isEditable: isEditable),
          ] else ...[
            _buildUnassignedState(isEditable: isEditable),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // State A: Unassigned
  // ----------------------------------------------------
  Widget _buildUnassignedState({required bool isEditable}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ValimaiColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ValimaiColors.cardBorder, width: 1),
              ),
              child: const Center(
                child: Icon(
                  Icons.event_busy_outlined,
                  size: 20,
                  color: ValimaiColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'No workout assigned',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'No training protocol currently planned for this date.',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isEditable) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openRoutineSelectionSheet(context),
              icon: const Icon(Icons.add, size: 16),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ----------------------------------------------------
  // State B: Workout Assigned
  // ----------------------------------------------------
  Widget _buildWorkoutAssignedState({
    required WorkoutRoutine? routine,
    required String? routineId,
    required bool isEditable,
  }) {
    final title = routine?.name ?? routineId ?? 'Assigned Workout';
    final exerciseCount = routine?.exercises.length ?? 0;
    final muscles = routine?.targetMuscleGroups.isNotEmpty == true
        ? routine!.targetMuscleGroups.join(', ')
        : 'Target Routine';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ValimaiColors.primaryContainer.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ValimaiColors.primaryContainer.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.fitness_center,
                  size: 20,
                  color: ValimaiColors.primaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$exerciseCount Exercises · $muscles',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isEditable) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openRoutineSelectionSheet(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: ValimaiColors.primaryContainer,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'CHANGE',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.primaryContainer,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearSelectedDate,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: ValimaiColors.cardBorder,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'CLEAR',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.secondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ----------------------------------------------------
  // State C: Rest Day
  // ----------------------------------------------------
  Widget _buildRestDayState({required bool isEditable}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ValimaiColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ValimaiColors.cardBorder, width: 1),
              ),
              child: const Center(
                child: Icon(
                  Icons.nightlight_round,
                  size: 20,
                  color: ValimaiColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Rest Day',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Scheduled recovery & muscular repair.',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isEditable) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openRoutineSelectionSheet(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: ValimaiColors.primaryContainer,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'CHANGE',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.primaryContainer,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearSelectedDate,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: ValimaiColors.cardBorder,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'CLEAR',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.secondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ==========================================
  // SECTION C: EXPLICIT SAVE BUTTON
  // ==========================================
  Widget _buildSaveButton() {
    final canSave = hasPendingChanges && !_isSaving;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: canSave ? _savePendingAssignment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ValimaiColors.primaryContainer,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ValimaiColors.surfaceContainerLow
              .withOpacity(0.4),
          disabledForegroundColor: ValimaiColors.secondary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canSave ? 4 : 0,
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check,
                    size: 16,
                    color: canSave
                        ? Colors.white
                        : ValimaiColors.secondary.withOpacity(0.4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasPendingChanges ? 'SAVE SCHEDULE' : 'NO PENDING CHANGES',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: canSave
                          ? Colors.white
                          : ValimaiColors.secondary.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ==========================================
  // DATE FORMATTING HELPERS
  // ==========================================
  String _formatMonthYear(DateTime date) {
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
      'December',
    ];
    return '${months[date.month]} ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    const months = [
      '',
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
    return '${months[date.month]} ${date.day}';
  }

  String _formatDateHeader(DateTime date) {
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
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: ValimaiColors.secondary,
          ),
        ),
      ),
    );
  }
}
