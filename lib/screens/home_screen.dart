import 'package:flutter/material.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/valimai_app_bar.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onStartWorkout;
  final ValueChanged<int>? onNavigateTab;

  const HomeScreen({
    super.key,
    this.onStartWorkout,
    this.onNavigateTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitializing = false;
  bool _isLoaded = false;

  void _handleStartWorkout() {
    if (_isInitializing || _isLoaded) return;
    setState(() {
      _isInitializing = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _isLoaded = true;
      });

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _isLoaded = false;
        });
        if (widget.onStartWorkout != null) {
          widget.onStartWorkout!();
        } else if (widget.onNavigateTab != null) {
          widget.onNavigateTab!(1); // Go to workouts
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ValimaiAppBar(title: 'Home'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GREETING & TEMPORAL CONTEXT
            _buildGreetingSection(),
            const SizedBox(height: 16),

            // RECOVERY STATUS PILL STRIP
            _buildRecoveryMatrixCard(),
            const SizedBox(height: 16),

            // 7-DAY CALENDAR MICRO STRIP
            _buildWeeklyOutputStrip(),
            const SizedBox(height: 20),

            // TODAY'S WORKOUT HERO CARD
            _buildTodayWorkoutHero(),
            const SizedBox(height: 20),

            // CONSISTENCY & ATHLETIC PERFORMANCE CARD
            _buildConsistencyCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: ValimaiColors.primaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'THURSDAY, OCT 24',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: ValimaiColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            ListenableBuilder(
              listenable: ProfileController.instance,
              builder: (context, _) {
                final name = ProfileController.instance.profile?.name ?? 'Alex';
                final firstName = name.trim().split(RegExp(r'\s+')).first;
                return Text(
                  'Good morning, $firstName',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: ValimaiColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                );
              },
            ),
            const Icon(
              Icons.bolt,
              color: ValimaiColors.secondary,
              size: 22,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Ready to push past your limits today?',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: ValimaiColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryMatrixCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
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
                  color: ValimaiColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite_outline,
                  color: ValimaiColors.primaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECOVERY MATRIX',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '92% • Peak Readiness Zone',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
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
                  'PR READY',
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
        ],
      ),
    );
  }

  Widget _buildWeeklyOutputStrip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEEKLY OUTPUT',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: ValimaiColors.secondary,
                ),
              ),
              Text(
                '4 OF 5 SESSIONS HIT',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: ValimaiColors.primaryContainer,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayItem('M', '21', isCompleted: true),
              _buildDayItem('T', '22', isCompleted: true),
              _buildDayItem('W', '23', isCompleted: true),
              _buildDayItem('T', '24', isToday: true),
              _buildDayItem('F', '25', isPlanned: true),
              _buildDayItem('S', '26', isRest: true),
              _buildDayItem('S', '27', isPlanned: true),
            ],
          ),
          const SizedBox(height: 12),
          // Micro week progress bar
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.80,
              child: Container(
                decoration: BoxDecoration(
                  color: ValimaiColors.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem(
    String dayLabel,
    String dayNum, {
    bool isCompleted = false,
    bool isToday = false,
    bool isPlanned = false,
    bool isRest = false,
  }) {
    if (isToday) {
      return Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: const Border(
            top: BorderSide(color: ValimaiColors.primaryContainer, width: 2),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
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
                color: ValimaiColors.primaryContainer,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dayNum,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ValimaiColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: ValimaiColors.primaryContainer,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 40,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
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
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isRest ? ValimaiColors.secondary : ValimaiColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          if (isCompleted)
            const Icon(
              Icons.check_circle,
              size: 14,
              color: ValimaiColors.primaryContainer,
            )
          else if (isRest)
            const Text(
              'REST',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: ValimaiColors.secondary,
              ),
            )
          else if (isPlanned)
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: ValimaiColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildTodayWorkoutHero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header badge row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ValimaiColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sports_score, size: 14, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      "TODAY'S PROGRAM • DAY 24",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HYPERTROPHY PHASE',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Workout Title & Target
          const Text(
            'CHEST & TRICEPS HYPERTROPHY',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ValimaiColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.adjust, size: 14, color: ValimaiColors.primaryContainer),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Target: Pectorals (Sternocostal & Clavicular), Anterior Deltoids, Lateral Triceps',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: ValimaiColors.secondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Columns Metrics Matrix
          Row(
            children: [
              Expanded(
                child: _buildMetricTile('VOLUME', '18 Sets', '6 Exercises'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile('DURATION', '~52 Mins', 'Rest: 90s-120s'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'INTENSITY',
                  'RPE 8.5',
                  'Heavy Load',
                  isAccent: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Core Sequence Preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CORE SEQUENCE (TOP 3 OF 6)',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: ValimaiColors.secondary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(1);
                  }
                },
                child: const Text(
                  'View All 6',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ValimaiColors.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _buildExerciseItem(
            '01',
            'Incline Dumbbell Bench Press',
            'Target: 34 kg × 8-10 reps',
            '4 SETS',
          ),
          const SizedBox(height: 6),
          _buildExerciseItem(
            '02',
            'Weighted Tricep Dips',
            'Target: +16 kg × 10-12 reps',
            '3 SETS',
          ),
          const SizedBox(height: 6),
          _buildExerciseItem(
            '03',
            'Standing Dual-Cable Flyes',
            'Target: 14 kg × 12-15 reps (Peak squeeze)',
            '4 SETS',
          ),
          const SizedBox(height: 16),

          // Big Kinetic Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleStartWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: ValimaiColors.primaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isInitializing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else if (_isLoaded)
                    const Icon(Icons.check, size: 20)
                  else
                    const Icon(Icons.play_arrow, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    _isInitializing
                        ? 'INITIALIZING SESSION...'
                        : _isLoaded
                            ? 'LOADED • ENTERING LOCKER'
                            : 'START WORKOUT',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Secondary Action
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextButton(
              onPressed: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(2); // Go to schedule
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: ValimaiColors.surfaceContainer,
                foregroundColor: ValimaiColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tune, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Modify Workout or Swap Rest Day',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, String sub, {bool isAccent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
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
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isAccent ? ValimaiColors.primaryContainer : ValimaiColors.onSurface,
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

  Widget _buildExerciseItem(String index, String title, String target, String sets) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  index,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    target,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sets,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: ValimaiColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ValimaiColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: ValimaiColors.primaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consistency & Streak',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ValimaiColors.onSurface,
                        ),
                      ),
                      Text(
                        'High adherence phase',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '14',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.primaryContainer,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'DAYS',
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
            ],
          ),
          const SizedBox(height: 14),

          // Progress breakdown container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Block Adherence',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        color: ValimaiColors.onSurface,
                      ),
                    ),
                    Text(
                      '18 / 20 Sessions',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ValimaiColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.90,
                    child: Container(
                      decoration: BoxDecoration(
                        color: ValimaiColors.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '94% MONTHLY TARGET',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                    Text(
                      '+2 AHEAD OF SCHEDULE',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: ValimaiColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Weekly Volume Metric Pill
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: ValimaiColors.secondary,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CUMULATIVE LOAD',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: ValimaiColors.secondary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '32,450 kg Lifted',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ValimaiColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 14,
                        color: ValimaiColors.primaryContainer,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '+8% VS LW',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ValimaiColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

