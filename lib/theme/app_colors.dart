import 'package:flutter/material.dart';

class AppColors {
  static const Color ink = Color(0xFF0B1E2D);
  static const Color inkSoft = Color(0xFF4C5D6C);
  static const Color inkMuted = Color(0xFF6E7E8E);
  static const Color surface = Color(0xFFF7F3EC);
  static const Color surfaceHigh = Color(0xFFFCFAF6);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3DED4);
  static const Color accent = Color(0xFF18C1B5);
  static const Color accentDark = Color(0xFF06383B);
  static const Color accentSoft = Color(0xFFBDEFE9);
  static const Color warning = Color(0xFFF2B365);
  static const Color headerTop = Color(0xFF0B1E2D);
  static const Color headerMid = Color(0xFF10324A);
  static const Color headerBottom = Color(0xFF0E5165);
  static const Color headerChip = Color(0xFF123349);
  static const Color headerChipBorder = Color(0xFF2A5672);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [headerTop, headerMid, headerBottom],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 10)),
  ];
}
