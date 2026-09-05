import 'package:flutter/material.dart';

const cream = Color(0xFFF3EEE4);
const cardBg = Color(0xFFFFFCF7);
const navy = Color(0xFF14202B);
const teal = Color(0xFF1F6B57);
const muted = Color(0xFF66707A);
const line = Color(0xFFE3D8C6);
const mint = Color(0xFFD8EFE6);

ThemeData heraldTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.fromSeed(seedColor: teal, surface: cream),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 40,
        height: 1.05,
        fontWeight: FontWeight.w600,
        color: navy,
      ),
      headlineMedium: TextStyle(
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w600,
        color: navy,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: navy,
      ),
      bodyMedium: TextStyle(fontSize: 15, height: 1.4, color: navy),
      bodySmall: TextStyle(fontSize: 13, color: muted),
    ),
  );
}