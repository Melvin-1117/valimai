import 'package:flutter/material.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';

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
            children: [
              // Kinetic Emblem
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ValimaiColors.primaryContainer, Color(0xFFC0001D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.bolt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VALIMAI',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: ValimaiColors.primaryContainer,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ValimaiColors.onSurface,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Actions
          Row(
            children: [
              if (showSearch)
                IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: ValimaiColors.secondaryLight,
                    size: 22,
                  ),
                  onPressed: onSearchTap,
                ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: ValimaiColors.secondaryLight,
                  size: 22,
                ),
                onPressed: onNotificationTap,
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onProfileTap,
                child: ListenableBuilder(
                  listenable: ProfileController.instance,
                  builder: (context, _) {
                    final initials = ProfileController.instance.profile?.initials ?? 'V';
                    return Container(
                      width: 32,
                      height: 32,
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
                            fontSize: 11,
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
