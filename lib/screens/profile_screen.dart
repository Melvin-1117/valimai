import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/valimai_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isRpeEnabled = true;
  bool _isLoggingOut = false;

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ValimaiColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Terminal Sign-Out',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            color: ValimaiColors.onSurface,
          ),
        ),
        content: const Text(
          'Terminate active session for Athlete #0842?',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: ValimaiColors.secondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                color: ValimaiColors.secondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _isLoggingOut = true);
              Future.delayed(const Duration(milliseconds: 900), () {
                if (!mounted) return;
                setState(() => _isLoggingOut = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terminal session terminated'),
                    backgroundColor: ValimaiColors.surfaceContainerHigh,
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ValimaiColors.primaryContainer,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'SIGN OUT',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ValimaiAppBar(
        title: 'Profile',
        showSearch: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Athlete Hero Header
            _buildAthleteHero(),
            const SizedBox(height: 20),

            // Biometric Telemetry & Readiness Quick Stats
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BIOMETRIC TELEMETRY',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: ValimaiColors.secondary,
                  ),
                ),
                Text(
                  'Live Sync',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: ValimaiColors.primaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 2x2 Biometrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildBiometricCard(
                    label: 'WEIGHT',
                    value: '82.4',
                    unit: 'KG',
                    subtitle: '-0.2 kg / wk target',
                    icon: Icons.scale,
                    subIcon: Icons.trending_down,
                    isHighlight: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBiometricCard(
                    label: 'BODY FAT',
                    value: '12.8',
                    unit: '%',
                    subtitle: 'DEXA Calibrated',
                    icon: Icons.pie_chart_outline,
                    subIcon: Icons.straighten,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildBiometricCard(
                    label: 'SKELETAL MUSCLE',
                    value: '41.2',
                    unit: 'KG',
                    subtitle: 'Peak Density',
                    icon: Icons.fitness_center,
                    subIcon: Icons.arrow_upward,
                    isHighlight: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBiometricCard(
                    label: 'COMPLIANCE',
                    value: '96',
                    unit: '%',
                    subtitle: '5 of 5 Sessions',
                    icon: Icons.verified_outlined,
                    isDot: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pro Member Card
            _buildProCard(),
            const SizedBox(height: 22),

            // Training Architecture Settings
            _buildSectionHeader('TRAINING ARCHITECTURE', Icons.tune),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: ValimaiColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ValimaiColors.cardBorder, width: 1),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.calendar_view_week,
                    title: 'Training Split',
                    subtitle: '5-Day Kinetic Hypertrophy',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ValimaiColors.primaryContainer.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: ValimaiColors.primaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingRow(
                    icon: Icons.sports_gymnastics,
                    title: 'Gym Equipment Profile',
                    subtitle: 'Full Barbell & Dumbbells, Cables',
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildRpeToggleRow(),
                  const Divider(height: 1, indent: 56),
                  _buildSettingRow(
                    icon: Icons.timer,
                    title: 'Rest Timer Haptics',
                    subtitle: 'Custom High-Pitch Beep • 90s Def.',
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // System Telemetry & Sync
            _buildSectionHeader('SYSTEM TELEMETRY & SYNC', Icons.sync_alt),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: ValimaiColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ValimaiColors.cardBorder, width: 1),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.watch,
                    title: 'Wearables Sync',
                    subtitle: 'Garmin HRM-Pro & Apple Watch',
                    trailing: Row(
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
                          'ONLINE',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: ValimaiColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingRow(
                    icon: Icons.file_download_outlined,
                    title: 'Export Performance Data',
                    subtitle: 'CSV, FIT & JSON Datasets',
                    trailing: const Icon(
                      Icons.open_in_new,
                      size: 18,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingRow(
                    icon: Icons.shield_outlined,
                    title: 'Security & Athlete Protocol',
                    subtitle: 'Biometric MFA • Support Concierge',
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Log out button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: _handleLogout,
                style: TextButton.styleFrom(
                  backgroundColor: ValimaiColors.surfaceContainer,
                  foregroundColor: ValimaiColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: ValimaiColors.cardBorder),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoggingOut)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ValimaiColors.secondary,
                        ),
                      )
                    else
                      const Icon(Icons.logout, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _isLoggingOut ? 'TERMINATING SESSION...' : 'LOG OUT OF TERMINAL',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Build Info
            const Center(
              child: Text(
                'VALIMAI OS v4.12.0 • CORE 0842-ALX',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: ValimaiColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAthleteHero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ValimaiColors.primaryContainer,
                    width: 2,
                  ),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCpH3I6sjmJbmKTvx62qarhseQPvxPIl3Gz4TjQ3bw6UvSG4EyeATmU7aFJKDAkc-0PGSkEEXBulVClT6s__0ODZdwtx12GartFHqU7a9OtiXXtIStSySsKzOz7rySAWPrWWQBWXmJYH3-nE5mg2hLfA_qrpiKEWZQ1TSevVxvUYDQcKVgEzl6ErJFNZ2Np6Hi9YZH3PT-QqGc9Kmcp8pAWCLoXyAQcJGne2uG9nfE',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: ValimaiColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bolt,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'VALIMAI ATHLETE #0842',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: ValimaiColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ValimaiColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TIER 1',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: ValimaiColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Alex Mercer',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: ValimaiColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Elite Tier • Hypertrophy Specialization',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: ValimaiColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 12,
                      color: ValimaiColors.secondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Joined March 2023',
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
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricCard({
    required String label,
    required String value,
    required String unit,
    required String subtitle,
    required IconData icon,
    IconData? subIcon,
    bool isHighlight = false,
    bool isDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ValimaiColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: ValimaiColors.secondary,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: isHighlight
                    ? ValimaiColors.primaryContainer
                    : ValimaiColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ValimaiColors.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ValimaiColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (isDot) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: ValimaiColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
              ] else if (subIcon != null) ...[
                Icon(
                  subIcon,
                  size: 12,
                  color: isHighlight
                      ? ValimaiColors.primaryContainer
                      : ValimaiColors.secondary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isHighlight
                      ? ValimaiColors.primaryContainer
                      : ValimaiColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ValimaiColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ValimaiColors.primaryContainer.withOpacity(0.25),
          width: 1,
        ),
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
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: ValimaiColors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'VALIMAI PRO MEMBER',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ValimaiColors.primaryContainer.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: ValimaiColors.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'All telemetry sensors, algorithmic load auto-regulation, and velocity transducers unlocked.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: ValimaiColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildProFeatureRow('AI Periodization Engine Active', Icons.auto_graph),
          const SizedBox(height: 6),
          _buildProFeatureRow('Real-time Bar Velocity Tracking', Icons.speed),
          const SizedBox(height: 6),
          _buildProFeatureRow('Infinite Cloud History & 1RM Mapping', Icons.all_inclusive),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: ValimaiColors.surfaceContainerLowest.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Renews Nov 24, 2024',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    color: ValimaiColors.secondary,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'MANAGE PLAN',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: ValimaiColors.primaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProFeatureRow(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ValimaiColors.primaryContainer),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ValimaiColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: ValimaiColors.secondary,
          ),
        ),
        Icon(icon, size: 16, color: ValimaiColors.secondary),
      ],
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: ValimaiColors.onSurface, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildRpeToggleRow() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune,
                  color: ValimaiColors.primaryContainer,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RPE & Intensity Scale',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ValimaiColors.onSurface,
                    ),
                  ),
                  Text(
                    _isRpeEnabled
                        ? 'Enabled (RPE 6 - 10 Gauge)'
                        : 'Disabled (Fixed Weights Only)',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: ValimaiColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () => setState(() => _isRpeEnabled = !_isRpeEnabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _isRpeEnabled
                    ? ValimaiColors.primaryContainer
                    : ValimaiColors.surfaceContainerHighest,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _isRpeEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
