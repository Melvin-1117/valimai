import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../services/exercise_controller.dart';
import '../theme/app_theme.dart';

class AddExerciseScreen extends StatefulWidget {
  final Set<String> existingExerciseNames;

  const AddExerciseScreen({super.key, this.existingExerciseNames = const {}});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  final Map<String, Exercise> _selectedExercises = {};
  bool _isReviewExpanded = false;

  @override
  void initState() {
    super.initState();
    // Ensure exercise library is initialized
    ExerciseController.instance.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExerciseSelection(Exercise exercise) {
    final nameLower = exercise.name.toLowerCase().trim();
    if (widget.existingExerciseNames.contains(nameLower)) {
      // Already in workout, cannot add again
      return;
    }

    setState(() {
      if (_selectedExercises.containsKey(exercise.id)) {
        _selectedExercises.remove(exercise.id);
      } else {
        _selectedExercises[exercise.id] = exercise;
      }
    });
  }

  void _openAddCustomExerciseDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ValimaiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => _CustomExerciseModal(
        onSaved: (Exercise newExercise) {
          setState(() {
            // Automatically select the newly created exercise
            _selectedExercises[newExercise.id] = newExercise;
            // Switch category if needed
            _selectedCategory = newExercise.primaryMuscleGroup;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Added "${newExercise.name}" to exercise library!',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
              backgroundColor: ValimaiColors.primaryContainer,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _confirmAndAddSelected() {
    if (_selectedExercises.isEmpty) return;
    Navigator.of(context).pop(_selectedExercises.values.toList());
  }

  @override
  Widget build(BuildContext context) {
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
          'ADD EXERCISE',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: ValimaiColors.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: _openAddCustomExerciseDialog,
                icon: const Icon(
                  Icons.add,
                  size: 14,
                  color: ValimaiColors.primaryContainer,
                ),
                label: const Text(
                  'CUSTOM',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: ValimaiColors.primaryContainer,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: ValimaiColors.primaryContainer.withOpacity(0.5),
                    width: 1,
                  ),
                  backgroundColor: ValimaiColors.primaryContainer.withOpacity(
                    0.08,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: ValimaiColors.cardBorder, height: 1),
        ),
      ),
      body: ListenableBuilder(
        listenable: ExerciseController.instance,
        builder: (context, _) {
          final controller = ExerciseController.instance;

          if (controller.isLoading && !controller.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(
                color: ValimaiColors.primaryContainer,
              ),
            );
          }

          final exercises = controller.searchExercises(
            _searchQuery,
            category: _selectedCategory == 'ALL' ? null : _selectedCategory,
          );

          return Column(
            children: [
              // SECTION A: SEARCH BAR
              _buildSearchBar(),

              // SECTION B: MUSCLE GROUP CATEGORIES
              _buildCategorySelector(controller),

              // SECTION C: EXERCISE LISTING
              Expanded(child: _buildExerciseList(exercises)),

              // SECTION D: SELECTED EXERCISES BOTTOM BAR
              if (_selectedExercises.isNotEmpty) _buildBottomBar(),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // SECTION A: SEARCH BAR
  // ==========================================
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: ValimaiColors.background,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: ValimaiColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ValimaiColors.cardBorder, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: ValimaiColors.secondary),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ValimaiColors.onSurface,
                ),
                cursorColor: ValimaiColors.primaryContainer,
                decoration: const InputDecoration(
                  hintText: 'Search by exercise name, muscle, equipment...',
                  hintStyle: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    color: ValimaiColors.secondary,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: ValimaiColors.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECTION B: MUSCLE GROUP CATEGORIES
  // ==========================================
  Widget _buildCategorySelector(ExerciseController controller) {
    final categories = ['ALL', ...MuscleGroupCategories.all];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          final count = cat == 'ALL'
              ? controller.allExercises.length
              : controller.countByCategory(cat);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? ValimaiColors
                          .primaryContainer // #F02D36
                    : ValimaiColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? ValimaiColors.primaryContainer
                      : ValimaiColors.cardBorder,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x4DF02D36),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  if (cat != 'ALL') ...[
                    Icon(
                      MuscleGroupCategories.getIcon(cat),
                      size: 13,
                      color: isSelected
                          ? Colors.white
                          : ValimaiColors.secondary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    cat.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : ValimaiColors.secondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.25)
                          : ValimaiColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : ValimaiColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // SECTION C: EXERCISE LISTING
  // ==========================================
  Widget _buildExerciseList(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: ValimaiColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: ValimaiColors.cardBorder, width: 1),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 24,
                  color: ValimaiColors.secondary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No exercises matching "$_searchQuery"'
                    : 'No exercises found in this category',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ValimaiColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try adjusting your search or tap "+ Custom" to create a new movement.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  color: ValimaiColors.secondary,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _openAddCustomExerciseDialog,
                icon: const Icon(
                  Icons.add,
                  size: 16,
                  color: ValimaiColors.primaryContainer,
                ),
                label: const Text(
                  'CREATE CUSTOM EXERCISE',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: ValimaiColors.primaryContainer,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: ValimaiColors.primaryContainer,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final nameLower = exercise.name.toLowerCase().trim();
        final bool isAlreadyInWorkout = widget.existingExerciseNames.contains(
          nameLower,
        );
        final bool isSelected = _selectedExercises.containsKey(exercise.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? ValimaiColors.primaryContainer.withOpacity(0.08)
                : ValimaiColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? ValimaiColors.primaryContainer
                  : isAlreadyInWorkout
                  ? ValimaiColors.cardBorder.withOpacity(0.4)
                  : ValimaiColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: isAlreadyInWorkout
                ? null
                : () => _toggleExerciseSelection(exercise),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Selection Checkbox / Indicator
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isAlreadyInWorkout
                          ? ValimaiColors.surfaceContainerLow
                          : isSelected
                          ? ValimaiColors.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isAlreadyInWorkout
                            ? ValimaiColors.cardBorder
                            : isSelected
                            ? ValimaiColors.primaryContainer
                            : ValimaiColors.secondary,
                        width: 1.5,
                      ),
                    ),
                    child: isAlreadyInWorkout
                        ? const Icon(
                            Icons.lock,
                            size: 12,
                            color: ValimaiColors.secondary,
                          )
                        : isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Exercise Name & Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                exercise.name,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isAlreadyInWorkout
                                      ? ValimaiColors.secondary
                                      : ValimaiColors.onSurface,
                                ),
                              ),
                            ),
                            if (exercise.isCustom) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ValimaiColors.primaryContainer
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'CUSTOM',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: ValimaiColors.primaryContainer,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                            if (isAlreadyInWorkout) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ValimaiColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'IN WORKOUT',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: ValimaiColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${exercise.primaryMuscleGroup} • ${exercise.equipment}${exercise.secondaryMuscleGroups.isNotEmpty ? " • Secondary: ${exercise.secondaryMuscleGroups.join(', ')}" : ""}',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            color: ValimaiColors.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // SECTION D: SELECTED EXERCISES BOTTOM BAR
  // ==========================================
  Widget _buildBottomBar() {
    final count = _selectedExercises.length;

    return Container(
      decoration: BoxDecoration(
        color: ValimaiColors.surface,
        border: const Border(
          top: BorderSide(color: ValimaiColors.cardBorder, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expandable review chips
          if (_isReviewExpanded) ...[
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              constraints: const BoxConstraints(maxHeight: 110),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedExercises.values.map((ex) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ValimaiColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ex.name,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ValimaiColors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedExercises.remove(ex.id);
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: ValimaiColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          Row(
            children: [
              // Selection Summary & Toggle Review
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isReviewExpanded = !_isReviewExpanded;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: ValimaiColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count == 1
                              ? '1 EXERCISE SELECTED'
                              : '$count EXERCISES SELECTED',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: ValimaiColors.onSurface,
                          ),
                        ),
                        Text(
                          _isReviewExpanded ? 'Tap to hide' : 'Tap to review',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 10,
                            color: ValimaiColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isReviewExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      size: 16,
                      color: ValimaiColors.secondary,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Confirm Button
              ElevatedButton(
                onPressed: _confirmAndAddSelected,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ValimaiColors.primaryContainer, // #F02D36
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'ADD TO WORKOUT ($count)',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SECTION E: ADD CUSTOM EXERCISE MODAL
// ==========================================
class _CustomExerciseModal extends StatefulWidget {
  final ValueChanged<Exercise> onSaved;

  const _CustomExerciseModal({required this.onSaved});

  @override
  State<_CustomExerciseModal> createState() => _CustomExerciseModalState();
}

class _CustomExerciseModalState extends State<_CustomExerciseModal> {
  final TextEditingController _nameController = TextEditingController();
  String _primaryMuscle = MuscleGroupCategories.chest;
  String _equipment = EquipmentTypes.barbell;
  final Set<String> _secondaryMuscles = {};
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitCustomExercise() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Exercise name is required.');
      return;
    }

    setState(() {
      _error = null;
      _isSaving = true;
    });

    final newEx = await ExerciseController.instance.addCustomExercise(
      name: name,
      primaryMuscleGroup: _primaryMuscle,
      secondaryMuscleGroups: _secondaryMuscles.toList(),
      equipment: _equipment,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (newEx != null) {
      widget.onSaved(newEx);
      Navigator.of(context).pop();
    } else {
      setState(() {
        _error =
            ExerciseController.instance.lastError ??
            'Failed to save custom exercise.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CREATE CUSTOM EXERCISE',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: ValimaiColors.secondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ValimaiColors.primaryContainer.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ValimaiColors.primaryContainer.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: ValimaiColors.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ValimaiColors.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Field: Name
            _buildFieldLabel('EXERCISE NAME *'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ValimaiColors.onSurface,
              ),
              cursorColor: ValimaiColors.primaryContainer,
              decoration: _inputDecoration('e.g. Incline Cable Fly'),
            ),
            const SizedBox(height: 14),

            // Field: Primary Muscle Group
            _buildFieldLabel('PRIMARY MUSCLE GROUP *'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: ValimaiColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ValimaiColors.cardBorder, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _primaryMuscle,
                  dropdownColor: ValimaiColors.surface,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.expand_more,
                    color: ValimaiColors.secondary,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ValimaiColors.onSurface,
                  ),
                  items: MuscleGroupCategories.all.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _primaryMuscle = val;
                        _secondaryMuscles.remove(val);
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Field: Equipment Type
            _buildFieldLabel('EQUIPMENT TYPE (OPTIONAL)'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: ValimaiColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ValimaiColors.cardBorder, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _equipment,
                  dropdownColor: ValimaiColors.surface,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.expand_more,
                    color: ValimaiColors.secondary,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ValimaiColors.onSurface,
                  ),
                  items: EquipmentTypes.all.map((eq) {
                    return DropdownMenuItem<String>(value: eq, child: Text(eq));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _equipment = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Field: Secondary Muscle Groups
            _buildFieldLabel('SECONDARY MUSCLE GROUPS (OPTIONAL)'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: MuscleGroupCategories.all
                  .where((c) => c != _primaryMuscle)
                  .map((cat) {
                    final isSelected = _secondaryMuscles.contains(cat);
                    return FilterChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : ValimaiColors.secondary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: ValimaiColors.primaryContainer,
                      backgroundColor: ValimaiColors.surfaceContainerLow,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: isSelected
                              ? ValimaiColors.primaryContainer
                              : ValimaiColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _secondaryMuscles.add(cat);
                          } else {
                            _secondaryMuscles.remove(cat);
                          }
                        });
                      },
                    );
                  })
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Save Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submitCustomExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ValimaiColors.primaryContainer,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: ValimaiColors.primaryContainer
                      .withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
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
                    : const Text(
                        'SAVE TO LIBRARY',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: ValimaiColors.secondary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 13,
        color: ValimaiColors.secondary,
      ),
      filled: true,
      fillColor: ValimaiColors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ValimaiColors.cardBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ValimaiColors.cardBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: ValimaiColors.primaryContainer,
          width: 1.5,
        ),
      ),
    );
  }
}
