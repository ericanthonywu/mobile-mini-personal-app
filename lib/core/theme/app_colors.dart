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
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // AI & Analytics Accents
  static const Color aiPurple = Color(0xFF8B5CF6);
  static const Color aiBlue = Color(0xFF3B82F6);
  static const Color aiCyan = Color(0xFF06B6D4);
  static const Color aiGradientStart = Color(0xFF6366F1);
  static const Color aiGradientEnd = Color(0xFFA855F7);

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF64748B);

  // Borders / dividers / pills
  static const Color border = Color(0xFF262C40);
  static const Color divider = Color(0xFF1E2235);
  static const Color pillBackground = Color(0xFF1A2035);
  static const Color cardSurface = Color(0xFF131828);

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
