import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_rotation.dart';
import 'daily_workout_controller.dart';

/// Data model for the 4 All-Time Overview metrics
class AllTimeOverviewData {
  final int totalWorkouts;
  final int trainingDays;
  final double totalVolumeKg;
  final bool hasWeightedVolume;
  final int currentStreak;

  const AllTimeOverviewData({
    required this.totalWorkouts,
    required this.trainingDays,
    required this.totalVolumeKg,
    required this.hasWeightedVolume,
    required this.currentStreak,
  });
}

/// Data model for a single week's workout frequency in a month
class WeeklyFrequencyItem {
  final String weekLabel;
  final String dateRangeLabel;
  final int workoutCount;

  const WeeklyFrequencyItem({
    required this.weekLabel,
    required this.dateRangeLabel,
    required this.workoutCount,
  });
}

/// Data model for Monthly Performance statistics and chart
class MonthlyAnalyticsData {
  final DateTime month;
  final int totalWorkouts;
  final int trainingDays;
  final double totalVolumeKg;
  final bool hasWeightedVolume;
  final List<WeeklyFrequencyItem> weeklyFrequency;

  const MonthlyAnalyticsData({
    required this.month,
    required this.totalWorkouts,
    required this.trainingDays,
    required this.totalVolumeKg,
    required this.hasWeightedVolume,
    required this.weeklyFrequency,
  });
}

/// Data model for an individual muscle group's training frequency
class MuscleDistributionItem {
  final String muscleGroup;
  final int count;
  final double percentage;

  const MuscleDistributionItem({
    required this.muscleGroup,
    required this.count,
    required this.percentage,
  });
}

/// Data model for a personal record on an individual exercise
class PersonalRecordItem {
  final String exerciseName;
  final double maxWeightKg;
  final int repsAtMaxWeight;
  final double bestSetVolumeKg;
  final DateTime date;

  const PersonalRecordItem({
    required this.exerciseName,
    required this.maxWeightKg,
    required this.repsAtMaxWeight,
    required this.bestSetVolumeKg,
    required this.date,
  });
}

/// Lightweight service calculating all profile analytics purely from genuine completed sessions and schedules
class ProfileAnalyticsService {
  /// Calculate the 4 All-Time Overview metrics
  static AllTimeOverviewData computeAllTimeOverview({
    required List<CompletedWorkoutSession> sessions,
    required Map<String, DaySchedule> schedules,
    DateTime? referenceDate,
  }) {
    final totalWorkouts = sessions.length;
    final trainingDays = sessions.map((s) => s.dateKey).toSet().length;

    double volume = 0.0;
    bool hasWeighted = false;

    for (final sess in sessions) {
      if (sess.workoutSnapshot != null) {
        for (final ex in sess.workoutSnapshot!.exercises) {
          for (final s in ex.effectiveSetConfigs) {
            if (s.weightKg > 0 && s.reps > 0) {
              volume += (s.weightKg * s.reps);
              hasWeighted = true;
            }
          }
        }
      } else if (sess.totalVolumeKg != null && sess.totalVolumeKg! > 0) {
        volume += sess.totalVolumeKg!;
        hasWeighted = true;
      }
    }

    final currentStreak = computeCurrentStreak(
      sessions: sessions,
      schedules: schedules,
      referenceDate: referenceDate,
    );

    return AllTimeOverviewData(
      totalWorkouts: totalWorkouts,
      trainingDays: trainingDays,
      totalVolumeKg: volume,
      hasWeightedVolume: hasWeighted,
      currentStreak: currentStreak,
    );
  }

  /// Calculate consecutive qualifying training days where explicit Rest Days preserve continuity
  static int computeCurrentStreak({
    required List<CompletedWorkoutSession> sessions,
    required Map<String, DaySchedule> schedules,
    DateTime? referenceDate,
  }) {
    if (sessions.isEmpty) return 0;

    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final completedDates = sessions
        .map(
          (s) => DateTime(
            s.completedAt.year,
            s.completedAt.month,
            s.completedAt.day,
          ),
        )
        .toSet();

    final isTodayCompleted = completedDates.contains(today);

    int streak = 0;
    DateTime checkDate;

    if (isTodayCompleted) {
      streak = 1;
      checkDate = today.subtract(const Duration(days: 1));
    } else {
      // If today is not completed yet (in progress, rest day, or pending workout),
      // evaluate streak continuity backwards starting from yesterday
      checkDate = today.subtract(const Duration(days: 1));
    }

    // Traverse backwards day-by-day
    while (true) {
      if (completedDates.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        final dateKey = DaySchedule.dateKey(checkDate);
        final schedule = schedules[dateKey];
        final isRest =
            schedule?.type == ScheduledDayType.rest ||
            DailyWorkoutController.instance
                    .getDailyWorkoutForDate(checkDate)
                    ?.isRest ==
                true;

        if (isRest) {
          // Explicit Rest Day preserves continuity without incrementing streak
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          // Unassigned date or missed scheduled workout breaks continuity
          break;
        }
      }
    }

    return streak;
  }

  /// Calculate monthly performance statistics and weekly frequency distribution
  static MonthlyAnalyticsData computeMonthlyAnalytics({
    required List<CompletedWorkoutSession> sessions,
    required DateTime viewingMonth,
  }) {
    final year = viewingMonth.year;
    final month = viewingMonth.month;

    // Filter sessions matching month and year
    final monthSessions = sessions.where((s) {
      return s.completedAt.year == year && s.completedAt.month == month;
    }).toList();

    final totalWorkouts = monthSessions.length;
    final trainingDays = monthSessions.map((s) => s.dateKey).toSet().length;

    double volume = 0.0;
    bool hasWeighted = false;

    for (final sess in monthSessions) {
      if (sess.workoutSnapshot != null) {
        for (final ex in sess.workoutSnapshot!.exercises) {
          for (final s in ex.effectiveSetConfigs) {
            if (s.weightKg > 0 && s.reps > 0) {
              volume += (s.weightKg * s.reps);
              hasWeighted = true;
            }
          }
        }
      } else if (sess.totalVolumeKg != null && sess.totalVolumeKg! > 0) {
        volume += sess.totalVolumeKg!;
        hasWeighted = true;
      }
    }

    // Build Monday-to-Sunday weekly distribution for the month
    final weeklyFrequency = _computeWeeklyFrequency(
      year: year,
      month: month,
      monthSessions: monthSessions,
    );

    return MonthlyAnalyticsData(
      month: DateTime(year, month, 1),
      totalWorkouts: totalWorkouts,
      trainingDays: trainingDays,
      totalVolumeKg: volume,
      hasWeightedVolume: hasWeighted,
      weeklyFrequency: weeklyFrequency,
    );
  }

  static List<WeeklyFrequencyItem> _computeWeeklyFrequency({
    required int year,
    required int month,
    required List<CompletedWorkoutSession> monthSessions,
  }) {
    const monthShorts = [
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
    final monthName = monthShorts[month];

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final items = <WeeklyFrequencyItem>[];

    DateTime weekStart = DateTime(year, month, 1);
    int weekIndex = 1;

    while (weekStart.day <= daysInMonth && weekStart.month == month) {
      // Find end of week (Sunday or end of month)
      final daysUntilSunday = 7 - weekStart.weekday;
      int endDay = weekStart.day + daysUntilSunday;
      if (endDay > daysInMonth) {
        endDay = daysInMonth;
      }

      final weekEnd = DateTime(year, month, endDay, 23, 59, 59);

      // Count sessions strictly falling within this calendar week window
      final count = monthSessions.where((s) {
        return !s.completedAt.isBefore(weekStart) &&
            !s.completedAt.isAfter(weekEnd);
      }).length;

      items.add(
        WeeklyFrequencyItem(
          weekLabel: 'W$weekIndex',
          dateRangeLabel:
              '${weekStart.day.toString().padLeft(2, '0')}-${endDay.toString().padLeft(2, '0')} $monthName',
          workoutCount: count,
        ),
      );

      weekIndex++;
      if (endDay >= daysInMonth) break;
      weekStart = DateTime(year, month, endDay + 1);
    }

    return items;
  }

  /// Calculate all-time muscle group distribution from completed exercise records
  static List<MuscleDistributionItem> computeMuscleDistribution({
    required List<CompletedWorkoutSession> sessions,
  }) {
    if (sessions.isEmpty) return const [];

    final counts = <String, int>{};
    for (final cat in MuscleGroupCategories.all) {
      counts[cat] = 0;
    }

    int totalExercises = 0;

    for (final sess in sessions) {
      if (sess.workoutSnapshot != null) {
        for (final ex in sess.workoutSnapshot!.exercises) {
          final target = ex.targetMuscle.toLowerCase().trim();
          final matchedCategory = _matchMuscleCategory(target);
          if (matchedCategory != null) {
            counts[matchedCategory] = (counts[matchedCategory] ?? 0) + 1;
            totalExercises++;
          }
        }
      } else if (sess.targetMuscleGroups != null) {
        final groups = sess.targetMuscleGroups!.split(',');
        for (final g in groups) {
          final matchedCategory = _matchMuscleCategory(g.toLowerCase().trim());
          if (matchedCategory != null) {
            counts[matchedCategory] = (counts[matchedCategory] ?? 0) + 1;
            totalExercises++;
          }
        }
      }
    }

    if (totalExercises == 0) return const [];

    final list = <MuscleDistributionItem>[];
    for (final entry in counts.entries) {
      if (entry.value > 0) {
        list.add(
          MuscleDistributionItem(
            muscleGroup: entry.key,
            count: entry.value,
            percentage: entry.value / totalExercises,
          ),
        );
      }
    }

    // Sort by count descending
    list.sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  static final Map<String, String> _knownAliases = {
    'chest': MuscleGroupCategories.chest,
    'pec': MuscleGroupCategories.chest,
    'pecs': MuscleGroupCategories.chest,
    'pectorals': MuscleGroupCategories.chest,
    'back': MuscleGroupCategories.back,
    'lat': MuscleGroupCategories.back,
    'lats': MuscleGroupCategories.back,
    'latissimus dorsi': MuscleGroupCategories.back,
    'trap': MuscleGroupCategories.back,
    'traps': MuscleGroupCategories.back,
    'rhomboids': MuscleGroupCategories.back,
    'shoulders': MuscleGroupCategories.shoulders,
    'shoulder': MuscleGroupCategories.shoulders,
    'delt': MuscleGroupCategories.shoulders,
    'delts': MuscleGroupCategories.shoulders,
    'deltoids': MuscleGroupCategories.shoulders,
    'biceps': MuscleGroupCategories.biceps,
    'bicep': MuscleGroupCategories.biceps,
    'triceps': MuscleGroupCategories.triceps,
    'tricep': MuscleGroupCategories.triceps,
    'abs': MuscleGroupCategories.abs,
    'ab': MuscleGroupCategories.abs,
    'core': MuscleGroupCategories.abs,
    'abdominals': MuscleGroupCategories.abs,
    'quadriceps': MuscleGroupCategories.quadriceps,
    'quad': MuscleGroupCategories.quadriceps,
    'quads': MuscleGroupCategories.quadriceps,
    'hamstrings': MuscleGroupCategories.hamstrings,
    'hamstring': MuscleGroupCategories.hamstrings,
    'glutes': MuscleGroupCategories.glutes,
    'glute': MuscleGroupCategories.glutes,
    'calves': MuscleGroupCategories.calves,
    'calf': MuscleGroupCategories.calves,
    'forearms': MuscleGroupCategories.forearms,
    'forearm': MuscleGroupCategories.forearms,
  };

  static String? _matchMuscleCategory(String raw) {
    final lower = raw.toLowerCase().trim();
    if (_knownAliases.containsKey(lower)) {
      return _knownAliases[lower];
    }
    for (final cat in MuscleGroupCategories.all) {
      final catLower = cat.toLowerCase();
      if (catLower == lower ||
          lower.contains(catLower) ||
          catLower.contains(lower)) {
        return cat;
      }
    }
    // Check substring aliases
    if (lower.contains('pec') || lower.contains('chest')) {
      return MuscleGroupCategories.chest;
    }
    if (lower.contains('lat') ||
        lower.contains('back') ||
        lower.contains('trap')) {
      return MuscleGroupCategories.back;
    }
    if (lower.contains('delt') || lower.contains('shoulder')) {
      return MuscleGroupCategories.shoulders;
    }
    if (lower.contains('arm') && lower.contains('bi')) {
      return MuscleGroupCategories.biceps;
    }
    if (lower.contains('arm') && lower.contains('tri')) {
      return MuscleGroupCategories.triceps;
    }
    if (lower.contains('core') || lower.contains('ab')) {
      return MuscleGroupCategories.abs;
    }
    if (lower.contains('quad') ||
        lower.contains('thigh') ||
        lower.contains('leg')) {
      return MuscleGroupCategories.quadriceps;
    }
    if (lower.contains('ham')) {
      return MuscleGroupCategories.hamstrings;
    }
    if (lower.contains('glute') || lower.contains('butt')) {
      return MuscleGroupCategories.glutes;
    }
    if (lower.contains('calf') || lower.contains('calves')) {
      return MuscleGroupCategories.calves;
    }

    return null;
  }

  /// Derive personal records across completed exercises
  static List<PersonalRecordItem> computePersonalRecords({
    required List<CompletedWorkoutSession> sessions,
  }) {
    if (sessions.isEmpty) return const [];

    final recordsMap = <String, PersonalRecordItem>{};

    for (final sess in sessions) {
      if (sess.workoutSnapshot == null) continue;

      for (final ex in sess.workoutSnapshot!.exercises) {
        final name = ex.name.trim();
        if (name.isEmpty) continue;

        for (final s in ex.effectiveSetConfigs) {
          if (s.weightKg <= 0 || s.reps <= 0) continue;

          final volume = s.weightKg * s.reps;
          final existing = recordsMap[name];

          if (existing == null ||
              s.weightKg > existing.maxWeightKg ||
              (s.weightKg == existing.maxWeightKg &&
                  s.reps > existing.repsAtMaxWeight)) {
            recordsMap[name] = PersonalRecordItem(
              exerciseName: name,
              maxWeightKg: s.weightKg,
              repsAtMaxWeight: s.reps,
              bestSetVolumeKg:
                  existing != null && existing.bestSetVolumeKg > volume
                  ? existing.bestSetVolumeKg
                  : volume,
              date: sess.completedAt,
            );
          } else if (volume > existing.bestSetVolumeKg) {
            recordsMap[name] = PersonalRecordItem(
              exerciseName: name,
              maxWeightKg: existing.maxWeightKg,
              repsAtMaxWeight: existing.repsAtMaxWeight,
              bestSetVolumeKg: volume,
              date: existing.date,
            );
          }
        }
      }
    }

    final list = recordsMap.values.toList();
    // Sort by max weight descending
    list.sort((a, b) => b.maxWeightKg.compareTo(a.maxWeightKg));
    return list;
  }
}
