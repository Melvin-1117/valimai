import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/valimai_app_bar.dart';

class ScheduleScreen extends StatefulWidget {
  final VoidCallback? onStartTodaySession;

  const ScheduleScreen({super.key, this.onStartTodaySession});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedView = 0; // 0: WEEK, 1: MONTH, 2: MESO
  final List<String> _views = ['WEEK', 'MONTH', 'MESO'];
  int _selectedDayIndex = 3; // Thu 24 by default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ValimaiAppBar(
        title: 'Schedule',
        showSearch: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header & Granularity Switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildIconButton(Icons.chevron_left, () {}),
                    const SizedBox(width: 8),
                    const Text(
                      'October 2024',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ValimaiColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(Icons.chevron_right, () {}),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: List.generate(_views.length, (index) {
                      final isSelected = _selectedView == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedView = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ValimaiColors.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _views[index],
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: isSelected ? Colors.white : ValimaiColors.secondary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Mesocycle Progress Strip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ValimaiColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ValimaiColors.cardBorder, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            'HYPERTROPHY MESO · WEEK 6',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: ValimaiColors.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'High Volume Microcycle',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 5,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ValimaiColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.78,
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
                        'Day 4 of 7 completed',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                      Text(
                        'Deload in 9 days',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ValimaiColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Weekly Timeline Reel
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MICROCYCLE 6 (OCT 21 – 27)',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: ValimaiColors.secondary,
                  ),
                ),
                Text(
                  '5 / 6 Completed',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ValimaiColors.primaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimelineDay(0, 'M', '21', statusIcon: Icons.check, isCompleted: true),
                _buildTimelineDay(1, 'T', '22', statusIcon: Icons.check, isCompleted: true),
                _buildTimelineDay(2, 'W', '23', statusIcon: Icons.bedtime, isRestCompleted: true),
                _buildTimelineDay(3, 'T', '24', isToday: true),
                _buildTimelineDay(4, 'F', '25', isDot: true),
                _buildTimelineDay(5, 'S', '26', isDot: true),
                _buildTimelineDay(6, 'S', '27', statusIcon: Icons.hotel, isRestFuture: true),
              ],
            ),
            const SizedBox(height: 22),

            // Scheduled Sessions Section
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SCHEDULED SESSIONS',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: ValimaiColors.secondary,
                  ),
                ),
                Text(
                  'Auto-synced',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Card 1: Today
            _buildTodaySessionCard(),
            const SizedBox(height: 14),

            // Card 2: Tomorrow
            _buildTomorrowSessionCard(),
            const SizedBox(height: 14),

            // Card 3: Saturday
            _buildSaturdaySessionCard(),
            const SizedBox(height: 14),

            // Card 4: Sunday Rest
            _buildSundayRestCard(),
            const SizedBox(height: 24),

            // Schedule Modifiers (Bento Toolbar)
            const Text(
              'SCHEDULE MODIFIERS',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: ValimaiColors.secondary,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildModifierCard(
                    icon: Icons.edit_calendar,
                    title: 'Reschedule',
                    subtitle: 'Shift workload',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModifierCard(
                    icon: Icons.sync,
                    title: 'Google Sync',
                    subtitle: 'Calendar stream',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _buildUnscheduledRestCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ValimaiColors.secondary, size: 18),
      ),
    );
  }

  Widget _buildTimelineDay(
    int index,
    String dayLabel,
    String dayNum, {
    bool isCompleted = false,
    bool isRestCompleted = false,
    bool isToday = false,
    bool isDot = false,
    bool isRestFuture = false,
    IconData? statusIcon,
  }) {
    final isSelected = _selectedDayIndex == index;

    if (isToday) {
      return GestureDetector(
        onTap: () => setState(() => _selectedDayIndex = index),
        child: Container(
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: ValimaiColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40FF5352),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'T',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '24',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt,
                  size: 11,
                  color: ValimaiColors.primaryContainer,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedDayIndex = index),
      child: Container(
        width: 42,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? ValimaiColors.surfaceContainerHighest
              : ValimaiColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: ValimaiColors.primaryContainer, width: 1)
              : null,
        ),
        child: Column(
          children: [
            Text(
              dayLabel,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ValimaiColors.secondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dayNum,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ValimaiColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            if (isCompleted || isRestCompleted || isRestFuture)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  size: 10,
                  color: isCompleted
                      ? ValimaiColors.primaryContainer
                      : ValimaiColors.secondary,
                ),
              )
            else if (isDot)
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: ValimaiColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySessionCard() {
    return Container(
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              color: ValimaiColors.primaryContainer,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 14, top: 14, bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ValimaiColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TODAY · OCT 24',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '17:30 LIFT',
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
                    const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: ValimaiColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chest & Triceps Hypertrophy',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Focus: Pec Minor Accents, Close-grip Press & Flyes',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    color: ValimaiColors.secondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Metrics grid
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ValimaiColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'EST DURATION',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: '52 ',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: ValimaiColors.onSurface,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'MIN',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 10,
                                      color: ValimaiColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: ValimaiColors.cardBorder,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'VOLUME LOAD',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: '18 ',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: ValimaiColors.onSurface,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'SETS',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 10,
                                      color: ValimaiColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: ValimaiColors.cardBorder,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'READINESS',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ValimaiColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.speed,
                                  size: 14,
                                  color: ValimaiColors.primaryContainer,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '96% PEAK',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: ValimaiColors.primaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Button row
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            if (widget.onStartTodaySession != null) {
                              widget.onStartTodaySession!();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ValimaiColors.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Start Session',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.format_list_numbered,
                        color: ValimaiColors.secondary,
                        size: 20,
                      ),
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

  Widget _buildTomorrowSessionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'TOMORROW · OCT 25',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '07:00 AM',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.primaryContainer,
                    ),
                  ),
                ],
              ),
              Icon(Icons.edit_calendar, size: 16, color: ValimaiColors.secondary),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Legs: Quad Dominant & Calves',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ValimaiColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Primary: Heavy Barbell Back Squats & Hack Squat Wave',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              color: ValimaiColors.secondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTag('60 MIN'),
              const SizedBox(width: 6),
              _buildTag('18 SETS'),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fitness_center, size: 12, color: ValimaiColors.onSurfaceVariant),
                    SizedBox(width: 4),
                    Text(
                      'SQUAT ACCELERATION',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: ValimaiColors.onSurfaceVariant,
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

  Widget _buildSaturdaySessionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'SATURDAY · OCT 26',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '10:00 AM',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.self_improvement,
                  size: 16,
                  color: ValimaiColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Active Recovery & Mobility Flow',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ValimaiColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Thoracic rotation, hip capsule opening & Zone 2 spin',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              color: ValimaiColors.secondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTag('30 MIN'),
              const SizedBox(width: 6),
              _buildTag('LOW INTENSITY'),
              const SizedBox(width: 6),
              _buildTag('ZONE 2'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSundayRestCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLowest,
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
                'SUNDAY · OCT 27',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: ValimaiColors.secondary,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.nightlight, size: 12, color: ValimaiColors.onSurfaceVariant),
                  SizedBox(width: 4),
                  Text(
                    'SLEEP TARGET: 8.5 HRS',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scheduled Full Rest Day',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Complete muscle glycogen refeed & neurological down-regulation',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
              Icon(Icons.hotel, color: ValimaiColors.secondary, size: 22),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModifierCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ValimaiColors.onSurface, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    color: ValimaiColors.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnscheduledRestCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
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
                  color: ValimaiColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pause_circle_outline,
                  color: ValimaiColors.onSurface,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insert Unscheduled Rest Day',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                  Text(
                    'Shifts remaining Microcycle sessions forward',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: ValimaiColors.secondary, size: 20),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: ValimaiColors.secondary,
        ),
      ),
    );
  }
}

