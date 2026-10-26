import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF007A5E); // Rich Green for Bayfay merchant
  static const Color primaryDark = Color(0xFF005642);
  static const Color primaryLight = Color(0xFFE8F5E9);
  static const Color secondary = Color(0xFFFF9800);

  // Legacy Android Parity Tokens
  static const Color brandBlue = Color(0xFF2196F3); // Android @color/logo / merchant_login
  static const Color brandLime = Color(0xFF92C42C); // Android @color/login_btn / signup
  static const Color brandDarkBlue = Color(0xFF0275D8);
  static const Color brandInputText = Color(0xFF262626);
  static const Color brandInputBorder = Color(0xFFB5B5B5);
  static const Color brandCardBorder = Color(0xFFBCBCBC);

  // Background & Surface
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF2F7);

  // Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFFE53935); // Modern soft crimson red for floating SnackBars
  static const Color info = Color(0xFF3B82F6);
}
