import 'package:flutter/material.dart';

class AppColors {
  static bool isDark = false;

  static Color get ink => isDark ? const Color(0xFFF8F9FA) : const Color(0xFF0B1E2D);
  static Color get inkSoft => isDark ? const Color(0xFFDEE2E6) : const Color(0xFF4C5D6C);
  static Color get inkMuted => isDark ? const Color(0xFFadb5bd) : const Color(0xFF6E7E8E);
  
  // OLED Dark Mode is pure black for deep blacks, card is dark gray
  static Color get surface => isDark ? const Color(0xFF000000) : const Color(0xFFF7F3EC);
  static Color get surfaceHigh => isDark ? const Color(0xFF121212) : const Color(0xFFFCFAF6);
  static Color get card => isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  static Color get border => isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE3DED4);
  
  static Color get accent => const Color(0xFF18C1B5);
  static Color get accentDark => isDark ? const Color(0xFFE0FFFD) : const Color(0xFF06383B);
  static Color get accentSoft => isDark ? const Color(0xFF004440) : const Color(0xFFBDEFE9);
  
  static Color get warning => const Color(0xFFF2B365);
  
  static Color get headerTop => isDark ? const Color(0xFF0F0F0F) : const Color(0xFF0B1E2D);
  static Color get headerMid => isDark ? const Color(0xFF161E24) : const Color(0xFF10324A);
  static Color get headerBottom => isDark ? const Color(0xFF10323C) : const Color(0xFF0E5165);
  
  static Color get headerChip => isDark ? const Color(0xFF2D2D2D) : const Color(0xFF123349);
  static Color get headerChipBorder => isDark ? const Color(0xFF424242) : const Color(0xFF2A5672);

  static LinearGradient get headerGradient => LinearGradient(
    colors: [headerTop, headerMid, headerBottom],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> get cardShadow => isDark 
      ? [const BoxShadow(color: Color(0x3A000000), blurRadius: 14, offset: Offset(0, 6))]
      : [const BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 10))];
}
