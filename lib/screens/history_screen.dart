import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/valimai_app_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedTimeframe = 1; // Last 30 Days
  final List<String> _timeframes = [
    'Last 7 Days',
    'Last 30 Days',
    'Current Meso',
    'All Time',
  ];

  final Set<int> _expandedLogs = {};

  void _toggleLog(int index) {
    setState(() {
      if (_expandedLogs.contains(index)) {
        _expandedLogs.remove(index);
      } else {
        _expandedLogs.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ValimaiAppBar(
        title: 'History',
        showSearch: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Pulse & Sub-Context
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          'PERFORMANCE ARCHIVE',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: ValimaiColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'MESO 04 : HYPERTROPHY',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ValimaiColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.download,
                    size: 18,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Timeframe Filter Carousel
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_timeframes.length, (index) {
                  final isSelected = _selectedTimeframe == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTimeframe = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ValimaiColors.primaryContainer
                              : ValimaiColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _timeframes[index].toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
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
            ),
            const SizedBox(height: 18),

            // Core Metric Bento Grid (2x2)
            Row(
              children: [
                Expanded(
                  child: _buildBentoCard(
                    title: 'GROSS VOLUME',
                    icon: Icons.fitness_center,
                    value: '142.8',
                    unit: 'T',
                    delta: '+12% MoM',
                    deltaPositive: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBentoCard(
                    title: 'COMPLETED',
                    icon: Icons.task_alt,
                    value: '22',
                    unit: 'Logs',
                    delta: '100% of target pace',
                    deltaPositive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildBentoCard(
                    title: 'IRON DURATION',
                    icon: Icons.timer,
                    value: '19h 45m',
                    unit: '',
                    delta: 'Avg 54m / session',
                    deltaPositive: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBentoCard(
                    title: 'PRS LOGGED',
                    icon: Icons.local_fire_department,
                    value: '05',
                    unit: 'New Max',
                    delta: 'Peak condition',
                    deltaPositive: true,
                    isPrCard: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Micro Volume Trend (Sparkline)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ValimaiColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ValimaiColors.cardBorder, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'WEEKLY DENSITY DELTA',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                      Text(
                        'PEAK LOAD',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ValimaiColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SparklinePainter(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // PR Spotlight Section
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.military_tech,
                      color: ValimaiColors.primaryContainer,
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Personal Records',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ValimaiColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Text(
                  'LATEST 30D',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // PR Horizontal Cards Carousel
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPrCard(
                    tag: 'NEW PR',
                    date: 'Oct 22',
                    title: 'Incline DB Press',
                    weight: '36',
                    reps: '× 8',
                    progression: '+2 kg Jump',
                    icon: Icons.trending_up,
                    isRedTag: true,
                  ),
                  const SizedBox(width: 10),
                  _buildPrCard(
                    tag: 'HEAVY SET',
                    date: 'Oct 18',
                    title: 'Weighted Dips',
                    weight: '+20',
                    reps: '× 8',
                    progression: '+4 kg progression',
                    icon: Icons.show_chart,
                  ),
                  const SizedBox(width: 10),
                  _buildPrCard(
                    tag: 'TIER 1 LIFT',
                    date: 'Oct 14',
                    title: 'Barbell Back Squat',
                    weight: '140',
                    reps: '× 5',
                    progression: 'Est. 1RM: 162 kg',
                    icon: Icons.bolt,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Execution Log Feed
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_edu,
                      color: ValimaiColors.secondary,
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Execution Log',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ValimaiColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Text(
                  'OCTOBER 2024',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Log Items
            _buildExecutionLogCard(
              index: 0,
              timeLabel: 'YESTERDAY',
              dateLabel: 'Oct 23, 18:15',
              title: 'Back & Rear Delts Hypertrophy',
              time: '54m',
              sets: '19',
              volume: '18.4t',
              strain: 'RPE 8',
              highlight: '3 Exercises over Target',
              isHighlightRed: true,
              exercises: const [
                'Chest Supported T-Bar Row | 4 sets • 80kg × 10',
                'Lat Pulldown (Neutral Grip) | 4 sets • 75kg × 12',
                'Reverse Pec Deck Delts | 4 sets • 50kg × 15',
                'Single Arm Cable Row | 3 sets • 35kg × 12',
              ],
            ),
            const SizedBox(height: 12),

            _buildExecutionLogCard(
              index: 1,
              timeLabel: 'MON, OCT 21',
              dateLabel: '07:30 AM',
              title: 'Push Day: Chest & Shoulders',
              time: '48m',
              sets: '16',
              volume: '15.2t',
              strain: 'RPE 8.5',
              highlight: 'Incline DB Record',
              isHighlightRed: true,
              exercises: const [
                'Incline DB Bench Press | 4 sets • 36kg × 8 (PR)',
                'Overhead Barbell Press | 4 sets • 60kg × 6',
                'Lateral Raises (Cable) | 5 sets • 14kg × 15',
              ],
            ),
            const SizedBox(height: 12),

            _buildExecutionLogCard(
              index: 2,
              timeLabel: 'SAT, OCT 19',
              dateLabel: '11:00 AM',
              title: 'Lower Body Heavy',
              time: '62m',
              sets: '18',
              volume: '22.9t',
              strain: 'RPE 9.0',
              highlight: 'High Ton Peak',
              isHighlightRed: false,
              exercises: const [
                'Barbell Back Squat | 5 sets • 140kg × 5',
                'Romanian Deadlift | 4 sets • 130kg × 8',
                'Standing Calf Raises | 4 sets • 110kg × 12',
              ],
            ),
            const SizedBox(height: 20),

            // Historical Vault Query
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ValimaiColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ValimaiColors.cardBorder, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HISTORICAL VAULT',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Looking for Mesocycles 01-03?',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: ValimaiColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ValimaiColors.surfaceContainerHigh,
                      foregroundColor: ValimaiColors.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                    ),
                    child: const Text(
                      'QUERY VAULT',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required IconData icon,
    required String value,
    required String unit,
    required String delta,
    required bool deltaPositive,
    bool isPrCard = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrCard
              ? ValimaiColors.primaryContainer.withOpacity(0.3)
              : ValimaiColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isPrCard
                      ? ValimaiColors.primaryContainer
                      : ValimaiColors.secondary,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: isPrCard
                    ? ValimaiColors.primaryContainer
                    : ValimaiColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isPrCard
                      ? ValimaiColors.primaryContainer
                      : ValimaiColors.onSurface,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            delta,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: deltaPositive
                  ? ValimaiColors.primaryContainer
                  : ValimaiColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrCard({
    required String tag,
    required String date,
    required String title,
    required String weight,
    required String reps,
    required String progression,
    required IconData icon,
    bool isRedTag = false,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isRedTag
                      ? ValimaiColors.primaryContainer
                      : ValimaiColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isRedTag ? Colors.white : ValimaiColors.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  color: ValimaiColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ValimaiColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                weight,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ValimaiColors.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'KG',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ValimaiColors.secondary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                reps,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ValimaiColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerHigh.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progression,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ValimaiColors.primaryContainer,
                  ),
                ),
                Icon(icon, size: 14, color: ValimaiColors.primaryContainer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionLogCard({
    required int index,
    required String timeLabel,
    required String dateLabel,
    required String title,
    required String time,
    required String sets,
    required String volume,
    required String strain,
    required String highlight,
    required bool isHighlightRed,
    required List<String> exercises,
  }) {
    final isExpanded = _expandedLogs.contains(index);

    return InkWell(
      onTap: () => _toggleLog(index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
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
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
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
                      dateLabel,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: ValimaiColors.primaryContainer.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.done_all,
                    size: 14,
                    color: ValimaiColors.primaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ValimaiColors.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            // 4 Column Grid
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ValimaiColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildLogMetric('TIME', time, false)),
                  Expanded(child: _buildLogMetric('SETS', sets, false)),
                  Expanded(child: _buildLogMetric('VOLUME', volume, true)),
                  Expanded(child: _buildLogMetric('STRAIN', strain, false)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bolt,
                      size: 14,
                      color: isHighlightRed
                          ? ValimaiColors.primaryContainer
                          : ValimaiColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      highlight,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ValimaiColors.secondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'BREAKDOWN',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: ValimaiColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
                      size: 16,
                      color: ValimaiColors.secondary,
                    ),
                  ],
                ),
              ],
            ),

            if (isExpanded) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: exercises.map((item) {
                    final parts = item.split('|');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            parts[0].trim(),
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              color: ValimaiColors.secondary,
                            ),
                          ),
                          Text(
                            parts.length > 1 ? parts[1].trim() : '',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ValimaiColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogMetric(String label, String value, bool isAccent) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: ValimaiColors.secondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isAccent ? ValimaiColors.primaryContainer : ValimaiColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final fillPath = Path();

    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.65),
      Offset(size.width * 0.4, size.height * 0.5),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.45),
      Offset(size.width, size.height * 0.15),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final cur = points[i];
      final c1 = Offset((prev.dx + cur.dx) / 2, prev.dy);
      final c2 = Offset((prev.dx + cur.dx) / 2, cur.dy);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, cur.dx, cur.dy);
      fillPath.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, cur.dx, cur.dy);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          ValimaiColors.primaryContainer.withOpacity(0.35),
          ValimaiColors.primaryContainer.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = ValimaiColors.primaryContainer
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Endpoint dot
    final dotPaint = Paint()..color = ValimaiColors.primaryContainer;
    canvas.drawCircle(points.last, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
