import 'package:flutter/material.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';

/// A reusable, premium App Logo widget for Expense Tracker.
///
/// Features customizable size, ambient glowing aura, rounded border glassmorphism,
/// and asset image loading with an elegant CustomPainter fallback.
class AppLogo extends StatelessWidget {
  /// The size (width & height) of the logo mark icon.
  final double size;

  /// Whether to show the ambient glowing shadow effect behind the logo.
  final bool showGlow;

  /// Optional app title text shown below or beside the logo icon.
  final bool showTitle;

  /// Optional subtitle text shown under the title.
  final String? subtitle;

  /// Optional Hero tag for seamless screen transition animations.
  final String? heroTag;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showGlow = true,
    this.showTitle = false,
    this.subtitle,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoIcon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: size * 0.4,
                  spreadRadius: size * 0.05,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF74B9FF).withValues(alpha: 0.25),
                  blurRadius: size * 0.6,
                  spreadRadius: size * 0.1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(size),
      ),
    );

    if (heroTag != null) {
      logoIcon = Hero(tag: heroTag!, child: logoIcon);
    }

    if (!showTitle) {
      return logoIcon;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoIcon,
        SizedBox(height: size * 0.2),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFEAEAEA),
              Color(0xFFA29BFE),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            "Eric's Expense Tracker",
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: (size * 0.22).clamp(16.0, 24.0),
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }

  /// Elegant vector CustomPainter fallback if the image file fails to load.
  Widget _buildFallbackIcon(double size) {
    return Container(
      color: const Color(0xFF1E1E2E),
      child: Center(
        child: Icon(
          Icons.account_balance_wallet_rounded,
          size: size * 0.5,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
