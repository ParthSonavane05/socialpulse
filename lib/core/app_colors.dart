import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color deepIndigo = Color(0xFF1A1A3E);
  static const Color midnightBlue = Color(0xFF0F0F2D);
  static const Color darkNavy = Color(0xFF0A0A1F);

  // Accent
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color softCyan = Color(0xFF80F0FF);
  static const Color lavender = Color(0xFFB388FF);
  static const Color softLavender = Color(0xFFD1C4E9);

  // Background
  static const Color bgDark = Color(0xFF0D0D1A);
  static const Color bgCard = Color(0xFF1A1A35);
  static const Color bgCardLight = Color(0xFF242448);
  static const Color bgGlass = Color(0x1AFFFFFF);

  // Status
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textMuted = Color(0xFF6E6E8A);

  // Gradients
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkNavy, deepIndigo, Color(0xFF12122A)],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, Color(0xFF00B8D4)],
  );

  static const LinearGradient lavenderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lavender, Color(0xFF7C4DFF)],
  );

  static const LinearGradient presenceRingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [neonCyan, lavender],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E40), Color(0xFF15152E)],
  );
}
