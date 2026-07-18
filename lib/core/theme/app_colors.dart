import 'package:flutter/material.dart';

/// App-wide color tokens.
/// All colors are tuned for dark mode only.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF16213E);
  static const Color surfaceHighlight = Color(0xFF1E1E3A);

  // Brand
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color primaryDark = Color(0xFF4A43CC);
  static const Color secondary = Color(0xFF00D9FF);

  // Semantic
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFFF5252);

  // Text
  static const Color textPrimary = Color(0xFFEAEAEA);
  static const Color textSecondary = Color(0xFF8A8A9A);
  static const Color textDisabled = Color(0xFF4A4A5A);

  // Borders / dividers
  static const Color border = Color(0xFF2A2A3E);
  static const Color divider = Color(0xFF1E1E2E);

  // Category preset colors (user can pick others)
  static const List<Color> categoryPresets = [
    Color(0xFFFF6B6B), // Food
    Color(0xFF4ECDC4), // Online Shopping
    Color(0xFF45B7D1), // Online Groceries
    Color(0xFF96CEB4), // Offline Groceries
    Color(0xFF95A5A6), // Others
    Color(0xFFFF8B94),
    Color(0xFFFFDAC1),
    Color(0xFFB5EAD7),
    Color(0xFFC7CEEA),
    Color(0xFFFECE00),
  ];
}
