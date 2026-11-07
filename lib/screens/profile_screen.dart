import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/valimai_app_bar.dart';
import 'edit_profile_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openEditProfile(BuildContext context, UserProfile profile, {bool focusBody = false}) {
    EditProfileSheet.show(
      context,
      profile: profile,
      focusBodyInfo: focusBody,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ValimaiColors.background,
      appBar: const ValimaiAppBar(
        title: 'Profile',
      ),
      body: ListenableBuilder(
        listenable: ProfileController.instance,
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
                      // Reload
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

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION A – PROFILE HEADER
                _buildProfileHeader(context, profile),
                const SizedBox(height: 28),

                // SECTION B – BODY INFORMATION
                _buildBodyInformationSection(context, profile),
                const SizedBox(height: 32),
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
          // Circular Avatar with Initials (or photo if present)
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

          // User Name
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

          // Edit Profile Action Button
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
  Widget _buildBodyInformationSection(BuildContext context, UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Edit Information action
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

        // 2x2 Grid of Body Metric Cards
        Row(
          children: [
            // Current Weight
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
            // Height
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
            // Age
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
            // Target Weight
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
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: ValimaiColors.secondary,
                ),
              ),
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
