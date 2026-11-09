import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../services/profile_analytics_service.dart';
import '../services/profile_controller.dart';
import '../services/workout_controller.dart';
import '../services/workout_history_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/valimai_app_bar.dart';
import 'edit_profile_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _openEditProfile(BuildContext context, UserProfile profile,
      {bool focusBody = false}) {
    EditProfileSheet.show(
      context,
      profile: profile,
      focusBodyInfo: focusBody,
    );
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    if (_isCurrentMonth) return;
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

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
      'December'
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
      'Dec'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ValimaiColors.background,
      appBar: const ValimaiAppBar(
        title: 'Profile',
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          ProfileController.instance,
          WorkoutHistoryController.instance,
          WorkoutController.instance,
        ]),
        builder: (context, _) {
          final profile = ProfileController.instance.profile;

          if (ProfileController.instance.isLoading && profile == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: ValimaiColors.primaryContainer,
              ),
            );
          }

          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No profile found.',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      ProfileController.instance.initialize();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ValimaiColors.primaryContainer,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            );
          }

          final sessions = WorkoutHistoryController.instance.allSessions;
          final schedules = WorkoutController.instance.schedules;

          final allTime = ProfileAnalyticsService.computeAllTimeOverview(
            sessions: sessions,
            schedules: schedules,
          );

          final monthlyData = ProfileAnalyticsService.computeMonthlyAnalytics(
            sessions: sessions,
            viewingMonth: _selectedMonth,
          );

          final muscleDistribution =
              ProfileAnalyticsService.computeMuscleDistribution(
            sessions: sessions,
          );

          final personalRecords = ProfileAnalyticsService.computePersonalRecords(
            sessions: sessions,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // SECTION 1 – PERSONAL PROFILE
                // ==========================================
                _buildProfileHeader(context, profile),
                const SizedBox(height: 24),

                _buildBodyInformationSection(context, profile),
                const SizedBox(height: 32),

                // ==========================================
                // SECTION 2 – OVERALL ANALYTICS
                // ==========================================
                _buildSectionHeader('OVERALL ANALYTICS', Icons.insights),
                const SizedBox(height: 16),

                // 2.1 All-Time Overview
                _buildAllTimeOverview(allTime),
                const SizedBox(height: 28),

                // 2.2 Monthly Performance & Weekly Frequency Chart
                _buildMonthlyPerformanceSection(monthlyData),
                const SizedBox(height: 28),

                // 2.3 Muscle Group Distribution
                _buildMuscleDistributionSection(muscleDistribution),
                const SizedBox(height: 28),

                // 2.4 Personal Records
                _buildPersonalRecordsSection(personalRecords),
                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // SECTION A – PROFILE HEADER
  // ==========================================
  Widget _buildProfileHeader(BuildContext context, UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ValimaiColors.surface, // Charcoal #25252B
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ValimaiColors.surfaceContainerHigh,
                  border: Border.all(
                    color: ValimaiColors.primaryContainer,
                    width: 2.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3DF02D36),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    profile.initials,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: ValimaiColors.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ValimaiColors.surface,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bolt,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ValimaiColors.onSurface,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openEditProfile(context, profile),
            icon: const Icon(
              Icons.edit_outlined,
              size: 15,
              color: ValimaiColors.primaryContainer,
            ),
            label: const Text(
              'EDIT PROFILE',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: ValimaiColors.onSurface,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: ValimaiColors.primaryContainer.withOpacity(0.4),
                width: 1,
              ),
              backgroundColor: ValimaiColors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION B – BODY INFORMATION
  // ==========================================
  Widget _buildBodyInformationSection(
      BuildContext context, UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'BODY INFORMATION',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: ValimaiColors.secondary,
              ),
            ),
            GestureDetector(
              onTap: () => _openEditProfile(context, profile, focusBody: true),
              child: const Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 16,
                    color: ValimaiColors.primaryContainer,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Edit Information',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'CURRENT WEIGHT',
                value: profile.currentWeight.toStringAsFixed(1),
                unit: 'KG',
                icon: Icons.scale_outlined,
                accentColor: ValimaiColors.primaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'HEIGHT',
                value: profile.height.toInt().toString(),
                unit: 'CM',
                icon: Icons.straighten_outlined,
                accentColor: ValimaiColors.secondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'AGE',
                value: profile.age.toString(),
                unit: 'YRS',
                icon: Icons.calendar_today_outlined,
                accentColor: ValimaiColors.secondaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'TARGET WEIGHT',
                value: profile.targetWeight != null
                    ? profile.targetWeight!.toStringAsFixed(1)
                    : '—',
                unit: profile.targetWeight != null ? 'KG' : 'NOT SET',
                icon: Icons.flag_outlined,
                accentColor: profile.targetWeight != null
                    ? ValimaiColors.primaryContainer
                    : ValimaiColors.secondary,
                isTarget: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ValimaiColors.primaryContainer),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: ValimaiColors.onSurface,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 2.1 – ALL-TIME OVERVIEW
  // ==========================================
  Widget _buildAllTimeOverview(AllTimeOverviewData data) {
    final volumeText = data.hasWeightedVolume
        ? '${data.totalVolumeKg.toInt()} kg'
        : '—';

    final streakText = data.currentStreak > 0
        ? '${data.currentStreak} ${data.currentStreak == 1 ? "DAY" : "DAYS"}'
        : '0 DAYS';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ALL-TIME OVERVIEW',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: ValimaiColors.secondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsStatCard(
                title: 'TOTAL WORKOUTS',
                value: '${data.totalWorkouts}',
                subtitle: 'Sessions Completed',
                icon: Icons.fitness_center,
                accentColor: ValimaiColors.primaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsStatCard(
                title: 'TRAINING DAYS',
                value: '${data.trainingDays}',
                subtitle: 'Unique Dates',
                icon: Icons.calendar_month,
                accentColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsStatCard(
                title: 'TOTAL VOLUME',
                value: volumeText,
                subtitle: data.hasWeightedVolume
                    ? 'Recorded weighted volume'
                    : 'No weighted lifts recorded',
                icon: Icons.scale,
                accentColor: ValimaiColors.primaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsStatCard(
                title: 'CURRENT STREAK',
                value: streakText,
                subtitle: data.currentStreak > 0
                    ? 'Active Consistency'
                    : 'Rest Days Allowed',
                icon: Icons.local_fire_department,
                accentColor: data.currentStreak > 0
                    ? const Color(0xFFFF5252)
                    : ValimaiColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 2.2 – MONTHLY PERFORMANCE & CHART
  // ==========================================
  Widget _buildMonthlyPerformanceSection(MonthlyAnalyticsData monthData) {
    final volumeText = monthData.hasWeightedVolume
        ? '${monthData.totalVolumeKg.toInt()} kg'
        : '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ValimaiColors.surface, // Charcoal #25252B
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatMonthYear(monthData.month).toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: ValimaiColors.onSurface,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _previousMonth,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: ValimaiColors.cardBorder, width: 1),
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
                    onTap: _isCurrentMonth ? null : _nextMonth,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _isCurrentMonth
                            ? ValimaiColors.surfaceContainerLow.withOpacity(0.4)
                            : ValimaiColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: ValimaiColors.cardBorder, width: 1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: _isCurrentMonth
                              ? ValimaiColors.secondary.withOpacity(0.4)
                              : ValimaiColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Monthly Statistics
          Row(
            children: [
              Expanded(
                child: _buildCompactMonthStat(
                  title: 'WORKOUTS',
                  value: '${monthData.totalWorkouts}',
                ),
              ),
              Expanded(
                child: _buildCompactMonthStat(
                  title: 'ACTIVE DAYS',
                  value: '${monthData.trainingDays}',
                ),
              ),
              Expanded(
                child: _buildCompactMonthStat(
                  title: 'VOLUME',
                  value: volumeText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            color: ValimaiColors.cardBorder,
          ),
          const SizedBox(height: 16),

          // Weekly Frequency Subtitle
          const Text(
            'WEEKLY WORKOUT FREQUENCY',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: ValimaiColors.secondary,
            ),
          ),
          const SizedBox(height: 14),

          // Frequency Chart or Empty State
          if (monthData.totalWorkouts == 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: ValimaiColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.bar_chart,
                    size: 24,
                    color: ValimaiColors.secondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No workouts recorded in this month.',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildWeeklyBarChart(monthData.weeklyFrequency),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactMonthStat({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: ValimaiColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: ValimaiColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyBarChart(List<WeeklyFrequencyItem> items) {
    final maxCount = items.fold<int>(
      1,
      (max, item) => item.workoutCount > max ? item.workoutCount : max,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((item) {
        final heightRatio =
            maxCount > 0 ? (item.workoutCount / maxCount).clamp(0.0, 1.0) : 0.0;
        final barHeight = item.workoutCount > 0 ? (heightRatio * 70) + 12 : 6.0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.workoutCount > 0)
                  Text(
                    '${item.workoutCount}',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: ValimaiColors.primaryContainer,
                    ),
                  )
                else
                  const SizedBox(height: 12),
                const SizedBox(height: 4),
                Container(
                  height: barHeight,
                  width: 24,
                  decoration: BoxDecoration(
                    color: item.workoutCount > 0
                        ? ValimaiColors.primaryContainer
                        : ValimaiColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                    gradient: item.workoutCount > 0
                        ? const LinearGradient(
                            colors: [
                              ValimaiColors.primaryContainer,
                              Color(0xFFFF6B6B),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.weekLabel,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.dateRangeLabel,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // SECTION 2.3 – MUSCLE GROUP DISTRIBUTION
  // ==========================================
  Widget _buildMuscleDistributionSection(List<MuscleDistributionItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MUSCLE GROUP DISTRIBUTION',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: ValimaiColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: ValimaiColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ValimaiColors.cardBorder, width: 1),
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.accessibility_new,
                  size: 26,
                  color: ValimaiColors.secondary,
                ),
                SizedBox(height: 8),
                Text(
                  'No muscle groups trained yet.',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Complete exercises in workouts to build your muscle distribution breakdown.',
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ValimaiColors.surface, // Charcoal #25252B
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ValimaiColors.cardBorder, width: 1),
            ),
            child: Column(
              children: items.map((item) {
                final percentInt = (item.percentage * 100).toInt();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                MuscleGroupCategories.getIcon(item.muscleGroup),
                                size: 14,
                                color: ValimaiColors.primaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.muscleGroup,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: ValimaiColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${item.count} ${item.count == 1 ? "exercise" : "exercises"}  ($percentInt%)',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: ValimaiColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: ValimaiColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: item.percentage.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  ValimaiColors.primaryContainer,
                                  Color(0xFFFF6B6B),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
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
    );
  }

  // ==========================================
  // SECTION 2.4 – PERSONAL RECORDS
  // ==========================================
  Widget _buildPersonalRecordsSection(List<PersonalRecordItem> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PERSONAL RECORDS',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: ValimaiColors.secondary,
          ),
        ),
        const SizedBox(height: 12),
        if (records.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: ValimaiColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ValimaiColors.cardBorder, width: 1),
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 26,
                  color: ValimaiColors.secondary,
                ),
                SizedBox(height: 8),
                Text(
                  'No personal records recorded yet.',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Complete weighted exercises in your sessions to establish benchmark personal records.',
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
          Column(
            children: records.map((pr) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ValimaiColors.surface, // Charcoal #25252B
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ValimaiColors.cardBorder, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ValimaiColors.primaryContainer.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ValimaiColors.primaryContainer.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events,
                          size: 18,
                          color: ValimaiColors.primaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pr.exerciseName,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: ValimaiColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Max: ${pr.maxWeightKg.toInt()} kg × ${pr.repsAtMaxWeight} reps · Best Set: ${pr.bestSetVolumeKg.toInt()} kg',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: ValimaiColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${pr.maxWeightKg.toInt()} KG',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: ValimaiColors.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAnalyticsStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ValimaiColors.surface, // Charcoal #25252B
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ),
              Icon(icon, size: 15, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: ValimaiColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: ValimaiColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
    bool isTarget = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ValimaiColors.surface, // Charcoal #25252B
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: ValimaiColors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                icon,
                size: 16,
                color: accentColor,
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
                  fontFamily: 'Montserrat',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isTarget && value == '—'
                      ? ValimaiColors.secondary
                      : ValimaiColors.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: ValimaiColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
