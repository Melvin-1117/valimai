import 'workout.dart';

/// Assignment of a routine or rest day to a specific day of the week (1 = Monday, 7 = Sunday)
class WeeklyDayAssignment {
  final int weekday; // 1 (Mon) to 7 (Sun)
  final ScheduledDayType type;
  final String? routineId;

  const WeeklyDayAssignment({
    required this.weekday,
    required this.type,
    this.routineId,
  });

  bool get isRest => type == ScheduledDayType.rest;
  bool get isWorkout => type == ScheduledDayType.workout && routineId != null;
  bool get isUnassigned => type == ScheduledDayType.unassigned;

  WeeklyDayAssignment copyWith({
    int? weekday,
    ScheduledDayType? type,
    String? routineId,
  }) {
    return WeeklyDayAssignment(
      weekday: weekday ?? this.weekday,
      type: type ?? this.type,
      routineId: routineId ?? this.routineId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekday': weekday,
      'type': type.name,
      'routineId': routineId,
    };
  }

  factory WeeklyDayAssignment.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'unassigned';
    final type = ScheduledDayType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => ScheduledDayType.unassigned,
    );
    return WeeklyDayAssignment(
      weekday: (json['weekday'] as num).toInt(),
      type: type,
      routineId: json['routineId'] as String?,
    );
  }

  static String weekdayName(int weekday) {
    const names = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    if (weekday >= 1 && weekday <= 7) return names[weekday];
    return 'Day $weekday';
  }

  static String weekdayShort(int weekday) {
    const names = ['', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    if (weekday >= 1 && weekday <= 7) return names[weekday];
    return 'D$weekday';
  }
}

