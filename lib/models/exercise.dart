import 'package:flutter/material.dart';

/// Standard 11 Muscle Group Categories in Valimai
class MuscleGroupCategories {
  static const String chest = 'Chest';
  static const String back = 'Back';
  static const String shoulders = 'Shoulders';
  static const String biceps = 'Biceps';
  static const String triceps = 'Triceps';
  static const String forearms = 'Forearms';
  static const String abs = 'Abs';
  static const String quadriceps = 'Quadriceps';
  static const String hamstrings = 'Hamstrings';
  static const String glutes = 'Glutes';
  static const String calves = 'Calves';

  static const List<String> all = [
    chest,
    back,
    shoulders,
    biceps,
    triceps,
    forearms,
    abs,
    quadriceps,
    hamstrings,
    glutes,
    calves,
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case chest:
        return Icons.fitness_center;
      case back:
        return Icons.shield_outlined;
      case shoulders:
        return Icons.accessibility_new;
      case biceps:
        return Icons.sports_kabaddi;
      case triceps:
        return Icons.flash_on;
      case forearms:
        return Icons.pan_tool_outlined;
      case abs:
        return Icons.crop_portrait;
      case quadriceps:
        return Icons.directions_walk;
      case hamstrings:
        return Icons.airline_seat_legroom_extra;
      case glutes:
        return Icons.airline_seat_recline_extra;
      case calves:
        return Icons.nordic_walking;
      default:
        return Icons.fitness_center;
    }
  }
}

/// Standard equipment types
class EquipmentTypes {
  static const String barbell = 'Barbell';
  static const String dumbbell = 'Dumbbell';
  static const String cable = 'Cable';
  static const String machine = 'Machine';
  static const String bodyweight = 'Bodyweight';
  static const String bands = 'Resistance Bands';
  static const String other = 'Other';

  static const List<String> all = [
    barbell,
    dumbbell,
    cable,
    machine,
    bodyweight,
    bands,
    other,
  ];
}

/// An independent Exercise item in the library
class Exercise {
  final String id;
  final String name;
  final String primaryMuscleGroup;
  final List<String> secondaryMuscleGroups;
  final String equipment;
  final bool isCustom;
  final DateTime createdAt;

  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscleGroup,
    this.secondaryMuscleGroups = const [],
    required this.equipment,
    this.isCustom = false,
    required this.createdAt,
  });

  Exercise copyWith({
    String? id,
    String? name,
    String? primaryMuscleGroup,
    List<String>? secondaryMuscleGroups,
    String? equipment,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryMuscleGroup: primaryMuscleGroup ?? this.primaryMuscleGroup,
      secondaryMuscleGroups:
          secondaryMuscleGroups ?? this.secondaryMuscleGroups,
      equipment: equipment ?? this.equipment,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primaryMuscleGroup': primaryMuscleGroup,
      'secondaryMuscleGroups': secondaryMuscleGroups,
      'equipment': equipment,
      'isCustom': isCustom,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final secondaries = (json['secondaryMuscleGroups'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    return Exercise(
      id: json['id'] as String? ?? 'ex_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Unnamed Exercise',
      primaryMuscleGroup:
          json['primaryMuscleGroup'] as String? ?? MuscleGroupCategories.chest,
      secondaryMuscleGroups: secondaries,
      equipment: json['equipment'] as String? ?? EquipmentTypes.barbell,
      isCustom: json['isCustom'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

