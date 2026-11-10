import 'package:flutter/material.dart';

import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import 'valimai_brand.dart';

/// Premium flagship top app bar for Valimai.
///
/// Features:
/// - Stylized athlete brand emblem with ambient crimson glow
/// - Metallic Valimai wordmark paired with active section indicator
/// - Tactile squircle action buttons with active notification pulse and profile badge
class ValimaiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const ValimaiAppBar({
    super.key,
    required this.title,
    this.showSearch = false,
    this.onSearchTap,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      height: preferredSize.height + topPadding,
      padding: EdgeInsets.only(
        top: topPadding,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: ValimaiColors.surface.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: ValimaiColors.cardBorder, width: 0.8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand Identity & Active Section Lockup
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Valimai Stylized Athlete Crest
              const ValimaiBrandEmblem(size: 38, showGlow: true),
              const SizedBox(width: 12),
              // Wordmark + Section Title Lockup
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Metallic Italic Wordmark
                  const ValimaiBrandWordmark(height: 14),
                  const SizedBox(height: 3),
                  // Active Section Indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: ValimaiColors.primaryContainer,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x80F02D36),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Right: Action Suite
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSearch) ...[
                _buildSearchTile(onSearchTap),
                const SizedBox(width: 8),
              ],
              _buildNotificationTile(context),
              const SizedBox(width: 8),
              _buildProfileTile(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTile(VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ValimaiColors.cardBorder, width: 1),
        ),
        child: const Center(
          child: Icon(
            Icons.search_rounded,
            color: ValimaiColors.secondaryLight,
            size: 19,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onNotificationTap != null) {
          onNotificationTap!();
        } else {
          _showNotificationsSheet(context);
        }
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: ValimaiColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ValimaiColors.cardBorder, width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: ValimaiColors.secondaryLight,
              size: 20,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ValimaiColors.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x99F02D36),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context) {
    return GestureDetector(
      onTap: onProfileTap,
      child: ListenableBuilder(
        listenable: ProfileController.instance,
        builder: (context, _) {
          final initials = ProfileController.instance.profile?.initials ?? 'V';
          return Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [ValimaiColors.surface, Color(0xFF1E1E24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: ValimaiColors.primaryContainer.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33F02D36),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: ValimaiColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: ValimaiColors.cardBorder, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NOTIFICATIONS',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: ValimaiColors.primaryContainer,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: ValimaiColors.secondaryLight, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ValimaiColors.cardBorder, width: 0.8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workout Scheduled Today',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Stay consistent. Your session is ready on Home.',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              color: ValimaiColors.secondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
