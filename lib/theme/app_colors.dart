import 'package:flutter/material.dart';

class AppColors {
  // Light theme
  static const lightBg = Color(0xFFF5F7FF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE8EAFF);
  static const lightText = Color(0xFF0A0A0F);
  static const lightTextSub = Color(0xFF6B7280);

  // Dark theme
  static const darkBg = Color(0xFF0A0A0F);
  static const darkSurface = Color(0xFF13131A);
  static const darkCard = Color(0xFF1C1C27);
  static const darkBorder = Color(0xFF2A2A3D);
  static const darkText = Color(0xFFF5F7FF);
  static const darkTextSub = Color(0xFF8892B0);

  // Global accents — used across all screens
  static const action = Color(0xFFFF6B35);    // warm orange — CTA, buttons, active UI
  static const gold   = Color(0xFFCA8A04);    // gold — XP, levels, rewards, streaks

  // Accents
  static const primary = Color(0xFFFF6B35);   // = action
  static const primaryDark = Color(0xFFE85D2A);
  static const secondary = Color(0xFFCA8A04); // = gold
  static const danger = Color(0xFFDC2626);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);

  // Section colors
  static const tasks       = Color(0xFF2979FF); // vivid blue
  static const habits      = Color(0xFFAA00FF); // vivid purple
  static const workouts    = Color(0xFFFF5722); // deep orange
  static const abstinences = Color(0xFFFF1744); // vivid red
  static const reading     = Color(0xFF00E676); // vivid green
  static const budget      = Color(0xFFFFD600); // vivid yellow
  static const food        = Color(0xFFFF4081); // vivid pink
  static const collection  = Color(0xFF00E5FF); // vivid cyan
  static const profile     = Color(0xFF7C4DFF); // vivid violet
}
