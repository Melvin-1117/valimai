import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable Valimai Brand Emblem displaying the stylized muscular athlete
/// with the glowing red circular aura.
class ValimaiBrandEmblem extends StatelessWidget {
  final double size;
  final bool showGlow;

  const ValimaiBrandEmblem({super.key, this.size = 32, this.showGlow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ValimaiColors.background,
        boxShadow: showGlow
            ? const [
                BoxShadow(
                  color: Color(0x66F02D36),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/branding/valimai_logo_emblem.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Elegant fallback for headless tests or missing assets
            return Container(
              color: ValimaiColors.primaryContainer,
              child: Center(
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: size * 0.55,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Reusable Valimai Metallic Italic Wordmark extracted from official brand artwork.
class ValimaiBrandWordmark extends StatelessWidget {
  final double height;
  final AlignmentGeometry alignment;

  const ValimaiBrandWordmark({
    super.key,
    this.height = 16,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Image.asset(
        'assets/branding/valimai_wordmark.png',
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Visually consistent styled fallback if asset is unavailable in tests
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VALIMAI',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: height * 0.75,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 2.0,
                  color: const Color(0xFFE6E6EA),
                ),
              ),
              Container(
                height: 2,
                width: height * 2.8,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ValimaiColors.primaryContainer,
                      Color(0xFFFF525A),
                      ValimaiColors.primaryContainer,
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
