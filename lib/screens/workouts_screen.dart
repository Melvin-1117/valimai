import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/valimai_app_bar.dart';

class WorkoutsScreen extends StatefulWidget {
  final VoidCallback? onStartSession;

  const WorkoutsScreen({super.key, this.onStartSession});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    'ALL PROTOCOLS',
    'HYPERTROPHY',
    'STRENGTH',
    'PUSH / PULL / LEGS',
    'QUICK (<45M)',
  ];

  bool _isContinuing = false;

  void _handleContinueProtocol() {
    setState(() {
      _isContinuing = true;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _isContinuing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session 28 • Push loaded into Active Terminal'),
          backgroundColor: ValimaiColors.primaryContainer,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ValimaiAppBar(
        title: 'Workouts',
        showSearch: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            _buildSearchBar(),
            const SizedBox(height: 12),

            // Category Filter Carousel
            _buildCategoryFilters(),
            const SizedBox(height: 20),

            // Active Master Training Program Hero
            _buildActiveProgramHero(),
            const SizedBox(height: 24),

            // Routines Header & Sorting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.view_agenda_outlined,
                      color: ValimaiColors.primaryContainer,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'DAILY ROUTINES',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: ValimaiColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'SORT: ',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        color: ValimaiColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Row(
                        children: [
                          Text(
                            'FREQUENCY',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: ValimaiColors.onSurface,
                            ),
                          ),
                          Icon(
                            Icons.expand_more,
                            size: 16,
                            color: ValimaiColors.secondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Daily Routine Cards
            _buildRoutineCard(
              blockTag: 'BLOCK 02 • SESSION A',
              intensityTag: 'RPE 8.5',
              title: 'Push Focus: Chest & Triceps',
              movements: '6 Lift Units',
              volume: '18 Working Sets',
              thirdMetricLabel: 'INTENSITY',
              thirdMetricValue: 'High RPE',
              badges: [
                'Clavicular Pectoral',
                'Sternal Head',
                'Lateral Triceps',
                'Anterior Delt',
              ],
              durationText: '~58 Mins Duration',
            ),
            const SizedBox(height: 14),

            _buildRoutineCard(
              blockTag: 'BLOCK 02 • SESSION B',
              intensityTag: 'RPE 8.0',
              title: 'Pull Focus: Heavy Back & Biceps',
              movements: '6 Lift Units',
              volume: '19 Working Sets',
              thirdMetricLabel: 'FATIGUE',
              thirdMetricValue: 'Moderate',
              previewChips: [
                'Lat Pulldown',
                'Chest-Supported Row',
                'Incline DB Curls',
              ],
              durationText: '~62 Mins Estimated',
            ),
            const SizedBox(height: 14),

            _buildRoutineCard(
              blockTag: 'HIGH INTENSITY',
              intensityTag: 'RPE 9.0',
              title: 'Lower Body: Posterior Chain & Quads',
              movements: '5 Heavy Units',
              volume: '16 Primary Sets',
              thirdMetricLabel: 'RECOVERY',
              thirdMetricValue: '48h Min',
              badges: [
                'Hamstring Complex',
                'Vastus Lateralis',
                'Gluteus Maximus',
              ],
              durationText: 'Target: High Neural Demand',
              hasRedAccentBar: true,
            ),
            const SizedBox(height: 14),

            _buildRoutineCard(
              blockTag: 'ACTIVE RECOVERY AUXILIARY',
              intensityTag: 'FAST CIRCUIT',
              title: 'Core & Metabolic Conditioning',
              movements: '4 Protocols',
              volume: '12 Rapid Sets',
              thirdMetricLabel: 'CLOCK',
              thirdMetricValue: '25 Mins Flat',
              badges: [
                'Hanging Leg Raise',
                'Ab Wheel Rollout',
                'SkiErg Sprints',
              ],
              durationText: 'Tempo: Constant Output',
            ),
            const SizedBox(height: 24),

            // Workshop & Network Section
            const Text(
              'WORKSHOP & NETWORK',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: ValimaiColors.secondary,
              ),
            ),
            const SizedBox(height: 10),

            _buildActionCard(
              icon: Icons.add_circle_outline,
              title: 'Create Custom Routine',
              subtitle: 'Set target metrics, rest intervals, and cues',
              onTap: () {},
            ),
            const SizedBox(height: 10),

            _buildActionCard(
              icon: Icons.public,
              title: 'Explore Community Splits',
              subtitle: 'Verified powerlifting and hypertrophy blocks',
              onTap: () {},
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: const Row(
        children: [
          Icon(Icons.search, color: ValimaiColors.secondary, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                color: ValimaiColors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search protocols, movements, splits...',
                hintStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  color: ValimaiColors.secondary,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Icon(Icons.mic, color: ValimaiColors.secondary, size: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategoryIndex = index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ValimaiColors.primaryContainer
                      : ValimaiColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? ValimaiColors.primaryContainer
                        : ValimaiColors.cardBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isSelected ? Colors.white : ValimaiColors.secondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveProgramHero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ValimaiColors.primaryContainer.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
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
                      'ACTIVE CYCLE',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: ValimaiColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'PHASE 02 // OVERLOAD',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: ValimaiColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'VALIMAI KINETIC HYPERTROPHY',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: ValimaiColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '5-Day Periodized Split • Block 2: Mechanical Tension',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: ValimaiColors.secondary,
            ),
          ),
          const SizedBox(height: 14),

          // Progress container
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
                    Row(
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 16,
                          color: ValimaiColors.primaryContainer,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Week 06 of 12',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ValimaiColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '50% COMPLETED',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: ValimaiColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: ValimaiColors.primaryContainer,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NEXT: SESSION 28 • PUSH',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                    Text(
                      '72 HRS TILL DELOAD',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleContinueProtocol,
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
                  if (_isContinuing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.play_arrow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isContinuing ? 'INITIALIZING LOG...' : 'CONTINUE PROTOCOL',
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
        ],
      ),
    );
  }

  Widget _buildRoutineCard({
    required String blockTag,
    required String intensityTag,
    required String title,
    required String movements,
    required String volume,
    required String thirdMetricLabel,
    required String thirdMetricValue,
    required String durationText,
    List<String>? badges,
    List<String>? previewChips,
    bool hasRedAccentBar = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasRedAccentBar)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: ValimaiColors.primaryContainer,
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              left: hasRedAccentBar ? 18 : 14,
              right: 14,
              top: 14,
              bottom: 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          blockTag,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: ValimaiColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: ValimaiColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          intensityTag,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ValimaiColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: ValimaiColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                // Metrics row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MOVEMENTS',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              movements,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VOLUME',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              volume,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thirdMetricLabel,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              thirdMetricValue,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Badges or sequence preview
                if (badges != null && badges.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: badges.map((badge) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ValimaiColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            color: ValimaiColors.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                if (previewChips != null && previewChips.isNotEmpty) ...[
                  const Text(
                    'SEQUENCE PREVIEW',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: previewChips.map((chip) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ValimaiColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: ValimaiColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              chip,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                color: ValimaiColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),

                // Footer action row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: ValimaiColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          durationText,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            color: ValimaiColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Text(
                          'START SESSION',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: ValimaiColors.primaryContainer,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: ValimaiColors.primaryContainer,
                        ),
                      ],
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ValimaiColors.cardBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: ValimaiColors.primaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ValimaiColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
            const Icon(
              Icons.chevron_right,
              color: ValimaiColors.secondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
