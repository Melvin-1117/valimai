import 'dart:convert';
import 'dart:io';
import '../models/exercise.dart';
import 'storage_helper.dart';

abstract class IExerciseStorage {
  Future<List<Exercise>> loadExercises();
  Future<bool> saveCustomExercise(Exercise exercise);
  Future<bool> saveAllExercises(List<Exercise> exercises);
}

class LocalExerciseStorage implements IExerciseStorage {
  static const String _fileName = 'valimai_exercises.json';
  List<Exercise>? _cachedExercises;

  @override
  Future<List<Exercise>> loadExercises() async {
    if (_cachedExercises != null) {
      return _cachedExercises!;
    }

    try {
      final content = await StorageHelper.safeReadString(_fileName);
      if (content != null && content.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(content);
        final loaded = jsonList
            .map((item) => Exercise.fromJson(item as Map<String, dynamic>))
            .toList();

        // Merge presets to ensure all canonical presets exist without duplicating
        final presets = getPresetExercises();
        final existingIds = loaded.map((e) => e.id).toSet();
        final existingNames =
            loaded.map((e) => e.name.toLowerCase().trim()).toSet();

        bool needsResave = false;
        for (final preset in presets) {
          if (!existingIds.contains(preset.id) &&
              !existingNames.contains(preset.name.toLowerCase().trim())) {
            loaded.add(preset);
            needsResave = true;
          }
        }

        if (needsResave) {
          try {
            await saveAllExercises(loaded);
          } catch (_) {}
        }

        _cachedExercises = loaded;
        return loaded;
      }
    } catch (_) {}

    // First launch seed
    final presets = getPresetExercises();
    _cachedExercises = presets;
    try {
      await saveAllExercises(presets);
    } catch (_) {}

    return presets;
  }

  @override
  Future<bool> saveCustomExercise(Exercise exercise) async {
    final list = await loadExercises();

    // Prevent duplicates by name
    final nameLower = exercise.name.toLowerCase().trim();
    final index =
        list.indexWhere((e) => e.name.toLowerCase().trim() == nameLower);

    if (index >= 0) {
      // Update existing
      list[index] = exercise;
    } else {
      list.add(exercise);
    }

    return saveAllExercises(list);
  }

  @override
  Future<bool> saveAllExercises(List<Exercise> exercises) async {
    _cachedExercises = List<Exercise>.from(exercises);
    try {
      final jsonList = exercises.map((e) => e.toJson()).toList();
      await StorageHelper.safeWriteString(_fileName, jsonEncode(jsonList));
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Preset Canonical Exercise Database (Seeded once)
  static List<Exercise> getPresetExercises() {
    final now = DateTime(2026, 1, 1);
    return [
      // 1. CHEST
      Exercise(
        id: 'ex_chest_barbell_bench_press',
        name: 'Barbell Bench Press',
        primaryMuscleGroup: MuscleGroupCategories.chest,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.triceps,
          MuscleGroupCategories.shoulders,
        ],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_chest_incline_barbell_bench_press',
        name: 'Incline Barbell Bench Press',
        primaryMuscleGroup: MuscleGroupCategories.chest,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.shoulders,
          MuscleGroupCategories.triceps,
        ],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_chest_dumbbell_bench_press',
        name: 'Dumbbell Bench Press',
        primaryMuscleGroup: MuscleGroupCategories.chest,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.triceps,
          MuscleGroupCategories.shoulders,
        ],
        equipment: EquipmentTypes.dumbbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_chest_incline_dumbbell_press',
        name: 'Incline Dumbbell Press',
        primaryMuscleGroup: MuscleGroupCategories.chest,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.shoulders,
          MuscleGroupCategories.triceps,
        ],
        equipment: EquipmentTypes.dumbbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_chest_decline_bench_press',
        name: 'Decline Bench Press',
        primaryMuscleGroup: MuscleGroupCategories.chest,
        secondaryMuscleGroups: const [MuscleGroupCategories.triceps],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_chest_dumbbell_fly',
        name: 'Dumbbell Fly',
        primaryMuscleGroup: MuscleGroupCategories.chest,
        secondaryMuscleGroups: const [MuscleGroupCategories.shoulders],
        equipment: EquipmentTypes.dumbbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_chest_cable_crossover',
        name: 'Cable Crossover',
        primaryMuscleGroup: MuscleGroupCategories.chest,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.cable,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_chest_pec_deck',
        name: 'Pec Deck',
        primaryMuscleGroup: MuscleGroupCategories.chest,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.machine,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_chest_push_ups',
        name: 'Push-ups',
        primaryMuscleGroup: MuscleGroupCategories.chest,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.triceps,
          MuscleGroupCategories.abs,
        ],
        equipment: EquipmentTypes.bodyweight,
        createdAt: now,
      ),

      // 2. BACK
      Exercise(
        id: 'ex_back_pull_ups',
        name: 'Pull-ups',
        primaryMuscleGroup: MuscleGroupCategories.back,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.biceps,
          MuscleGroupCategories.forearms,
        ],
        equipment: EquipmentTypes.bodyweight,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_back_lat_pulldown',
        name: 'Lat Pulldown',
        primaryMuscleGroup: MuscleGroupCategories.back,
        secondaryMuscleGroups: const [MuscleGroupCategories.biceps],
        equipment: EquipmentTypes.cable,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_back_barbell_bent_over_row',
        name: 'Barbell Bent-over Row',
        primaryMuscleGroup: MuscleGroupCategories.back,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.biceps,
          MuscleGroupCategories.hamstrings,
        ],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_back_seated_cable_row',
        name: 'Seated Cable Row',
        primaryMuscleGroup: MuscleGroupCategories.back,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.biceps,
          MuscleGroupCategories.forearms,
        ],
        equipment: EquipmentTypes.cable,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_back_single_arm_dumbbell_row',
        name: 'Single-arm Dumbbell Row',
        primaryMuscleGroup: MuscleGroupCategories.back,
        secondaryMuscleGroups: const [MuscleGroupCategories.biceps],
        equipment: EquipmentTypes.dumbbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_back_t_bar_row',
        name: 'T-bar Row',
        primaryMuscleGroup: MuscleGroupCategories.back,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.biceps,
          MuscleGroupCategories.shoulders,
        ],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_back_straight_arm_pulldown',
        name: 'Straight-arm Pulldown',
        primaryMuscleGroup: MuscleGroupCategories.back,
        secondaryMuscleGroups: const [MuscleGroupCategories.triceps],
        equipment: EquipmentTypes.cable,
        createdAt: now,
      ),

      // 3. SHOULDERS
      Exercise(
        id: 'ex_sh_overhead_press',
        name: 'Overhead Press',
        primaryMuscleGroup: MuscleGroupCategories.shoulders,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.triceps,
          MuscleGroupCategories.abs,
        ],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_sh_dumbbell_shoulder_press',
        name: 'Dumbbell Shoulder Press',
        primaryMuscleGroup: MuscleGroupCategories.shoulders,
        secondaryMuscleGroups: const [MuscleGroupCategories.triceps],
        equipment: EquipmentTypes.dumbbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_sh_lateral_raise',
        name: 'Lateral Raise',
        primaryMuscleGroup: MuscleGroupCategories.shoulders,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.dumbbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_sh_front_raise',
        name: 'Front Raise',
        primaryMuscleGroup: MuscleGroupCategories.shoulders,
        secondaryMuscleGroups: const [MuscleGroupCategories.chest],
        equipment: EquipmentTypes.dumbbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_sh_reverse_pec_deck',
        name: 'Reverse Pec Deck',
        primaryMuscleGroup: MuscleGroupCategories.shoulders,
        secondaryMuscleGroups: const [MuscleGroupCategories.back],
        equipment: EquipmentTypes.machine,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_sh_face_pull',
        name: 'Face Pull',
        primaryMuscleGroup: MuscleGroupCategories.shoulders,
        secondaryMuscleGroups: const [MuscleGroupCategories.back],
        equipment: EquipmentTypes.cable,
        createdAt: now,
      ),

      // 4. BICEPS
      Exercise(
        id: 'ex_bi_barbell_curl',
        name: 'Barbell Curl',
        primaryMuscleGroup: MuscleGroupCategories.biceps,
        secondaryMuscleGroups: const [MuscleGroupCategories.forearms],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_bi_dumbbell_curl',
        name: 'Dumbbell Curl',
        primaryMuscleGroup: MuscleGroupCategories.biceps,
        secondaryMuscleGroups: const [MuscleGroupCategories.forearms],
        equipment: EquipmentTypes.dumbbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_bi_hammer_curl',
        name: 'Hammer Curl',
        primaryMuscleGroup: MuscleGroupCategories.biceps,
        secondaryMuscleGroups: const [MuscleGroupCategories.forearms],
        equipment: EquipmentTypes.dumbbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_bi_preacher_curl',
        name: 'Preacher Curl',
        primaryMuscleGroup: MuscleGroupCategories.biceps,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_bi_concentration_curl',
        name: 'Concentration Curl',
        primaryMuscleGroup: MuscleGroupCategories.biceps,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.dumbbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_bi_cable_curl',
        name: 'Cable Curl',
        primaryMuscleGroup: MuscleGroupCategories.biceps,
        secondaryMuscleGroups: const [MuscleGroupCategories.forearms],
        equipment: EquipmentTypes.cable,
        createdAt: now,
      ),

      // 5. TRICEPS
      Exercise(
        id: 'ex_tri_cable_pushdown',
        name: 'Cable Pushdown',
        primaryMuscleGroup: MuscleGroupCategories.triceps,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.cable,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_tri_rope_pushdown',
        name: 'Rope Pushdown',
        primaryMuscleGroup: MuscleGroupCategories.triceps,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.cable,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_tri_skull_crushers',
        name: 'Skull Crushers',
        primaryMuscleGroup: MuscleGroupCategories.triceps,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_tri_overhead_triceps_extension',
        name: 'Overhead Triceps Extension',
        primaryMuscleGroup: MuscleGroupCategories.triceps,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.dumbbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_tri_close_grip_bench_press',
        name: 'Close-grip Bench Press',
        primaryMuscleGroup: MuscleGroupCategories.triceps,
        secondaryMuscleGroups: const [MuscleGroupCategories.chest],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_tri_triceps_dips',
        name: 'Triceps Dips',
        primaryMuscleGroup: MuscleGroupCategories.triceps,
        secondaryMuscleGroups: const [MuscleGroupCategories.chest],
        equipment: EquipmentTypes.bodyweight,
        createdAt: now,
      ),

      // 6. FOREARMS
      Exercise(
        id: 'ex_fore_wrist_curl',
        name: 'Wrist Curl',
        primaryMuscleGroup: MuscleGroupCategories.forearms,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_fore_reverse_wrist_curl',
        name: 'Reverse Wrist Curl',
        primaryMuscleGroup: MuscleGroupCategories.forearms,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_fore_farmers_walk',
        name: "Farmer's Walk",
        primaryMuscleGroup: MuscleGroupCategories.forearms,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.back,
          MuscleGroupCategories.abs,
        ],
        equipment: EquipmentTypes.dumbbell,
        createdAt: now,
      ),

      // 7. ABS
      Exercise(
        id: 'ex_abs_crunches',
        name: 'Crunches',
        primaryMuscleGroup: MuscleGroupCategories.abs,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.bodyweight,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_abs_reverse_crunches',
        name: 'Reverse Crunches',
        primaryMuscleGroup: MuscleGroupCategories.abs,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.bodyweight,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_abs_hanging_leg_raises',
        name: 'Hanging Leg Raises',
        primaryMuscleGroup: MuscleGroupCategories.abs,
        secondaryMuscleGroups: const [MuscleGroupCategories.forearms],
        equipment: EquipmentTypes.bodyweight,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_abs_plank',
        name: 'Plank',
        primaryMuscleGroup: MuscleGroupCategories.abs,
        secondaryMuscleGroups: const [MuscleGroupCategories.shoulders],
        equipment: EquipmentTypes.bodyweight,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_abs_cable_crunch',
        name: 'Cable Crunch',
        primaryMuscleGroup: MuscleGroupCategories.abs,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.cable,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_abs_russian_twist',
        name: 'Russian Twist',
        primaryMuscleGroup: MuscleGroupCategories.abs,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.bodyweight,
        createdAt: now,
      ),

      // 8. QUADRICEPS
      Exercise(
        id: 'ex_quad_barbell_squat',
        name: 'Barbell Squat',
        primaryMuscleGroup: MuscleGroupCategories.quadriceps,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.glutes,
          MuscleGroupCategories.hamstrings,
        ],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_quad_front_squat',
        name: 'Front Squat',
        primaryMuscleGroup: MuscleGroupCategories.quadriceps,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.glutes,
          MuscleGroupCategories.abs,
        ],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_quad_leg_press',
        name: 'Leg Press',
        primaryMuscleGroup: MuscleGroupCategories.quadriceps,
        secondaryMuscleGroups: const [MuscleGroupCategories.glutes],
        equipment: EquipmentTypes.machine,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_quad_leg_extension',
        name: 'Leg Extension',
        primaryMuscleGroup: MuscleGroupCategories.quadriceps,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.machine,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_quad_bulgarian_split_squat',
        name: 'Bulgarian Split Squat',
        primaryMuscleGroup: MuscleGroupCategories.quadriceps,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.glutes,
          MuscleGroupCategories.hamstrings,
        ],
        equipment: EquipmentTypes.dumbbell,
        createdAt: now,
      ),

      // 9. HAMSTRINGS
      Exercise(
        id: 'ex_ham_romanian_deadlift',
        name: 'Romanian Deadlift',
        primaryMuscleGroup: MuscleGroupCategories.hamstrings,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.glutes,
          MuscleGroupCategories.back,
        ],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_ham_lying_leg_curl',
        name: 'Lying Leg Curl',
        primaryMuscleGroup: MuscleGroupCategories.hamstrings,
        secondaryMuscleGroups: const [MuscleGroupCategories.calves],
        equipment: EquipmentTypes.machine,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_ham_seated_leg_curl',
        name: 'Seated Leg Curl',
        primaryMuscleGroup: MuscleGroupCategories.hamstrings,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.machine,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_ham_good_morning',
        name: 'Good Morning',
        primaryMuscleGroup: MuscleGroupCategories.hamstrings,
        secondaryMuscleGroups: const [
          MuscleGroupCategories.glutes,
          MuscleGroupCategories.back,
        ],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),

      // 10. GLUTES
      Exercise(
        id: 'ex_glute_hip_thrust',
        name: 'Hip Thrust',
        primaryMuscleGroup: MuscleGroupCategories.glutes,
        secondaryMuscleGroups: const [MuscleGroupCategories.hamstrings],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_glute_glute_bridge',
        name: 'Glute Bridge',
        primaryMuscleGroup: MuscleGroupCategories.glutes,
        secondaryMuscleGroups: const [MuscleGroupCategories.hamstrings],
        equipment: EquipmentTypes.bodyweight,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_glute_cable_kickback',
        name: 'Cable Kickback',
        primaryMuscleGroup: MuscleGroupCategories.glutes,
        secondaryMuscleGroups: const [MuscleGroupCategories.hamstrings],
        equipment: EquipmentTypes.cable,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_glute_sumo_squat',
        name: 'Sumo Squat',
        primaryMuscleGroup: MuscleGroupCategories.glutes,
        secondaryMuscleGroups: const [MuscleGroupCategories.quadriceps],
        equipment: EquipmentTypes.barbell,
        createdAt: now,
      ),

      // 11. CALVES
      Exercise(
        id: 'ex_calf_standing_calf_raise',
        name: 'Standing Calf Raise',
        primaryMuscleGroup: MuscleGroupCategories.calves,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.machine,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_calf_seated_calf_raise',
        name: 'Seated Calf Raise',
        primaryMuscleGroup: MuscleGroupCategories.calves,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.machine,
        createdAt: now,
      ),
      Exercise(
        id: 'ex_calf_leg_press_calf_raise',
        name: 'Leg Press Calf Raise',
        primaryMuscleGroup: MuscleGroupCategories.calves,
        secondaryMuscleGroups: const [],
        equipment: EquipmentTypes.machine,
        createdAt: now,
      ),
    ];
  }
}

