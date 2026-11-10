import 'package:flutter/material.dart';

import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import 'valimai_brand.dart';

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
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: ValimaiColors.surface.withOpacity(0.9),
        border: const Border(
          bottom: BorderSide(color: ValimaiColors.cardBorder, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Title
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Valimai Brand Emblem
              const ValimaiBrandEmblem(size: 38, showGlow: true),
              const SizedBox(width: 10),
              // Valimai Metallic Wordmark
              const ValimaiBrandWordmark(height: 20),
              const SizedBox(width: 10),
              // Section Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: ValimaiColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: ValimaiColors.cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: ValimaiColors.secondaryLight,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSearch)
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ValimaiColors.surfaceContainerHigh,
                    border: Border.all(
                      color: ValimaiColors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.search,
                      color: ValimaiColors.secondaryLight,
                      size: 18,
                    ),
                    onPressed: onSearchTap,
                  ),
                ),
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ValimaiColors.surfaceContainerHigh,
                  border: Border.all(color: ValimaiColors.cardBorder, width: 1),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: ValimaiColors.secondaryLight,
                    size: 18,
                  ),
                  onPressed: onNotificationTap,
                ),
              ),
              GestureDetector(
                onTap: onProfileTap,
                child: ListenableBuilder(
                  listenable: ProfileController.instance,
                  builder: (context, _) {
                    final initials =
                        ProfileController.instance.profile?.initials ?? 'V';
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ValimaiColors.surfaceContainerHigh,
                        border: Border.all(
                          color: ValimaiColors.primaryContainer,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
