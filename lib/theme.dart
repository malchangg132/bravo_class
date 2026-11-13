import 'package:flutter/material.dart';

import 'models.dart';

class C {
  static const blue = Color(0xFF2563EB);
  static const navy = Color(0xFF0B4A9E);
  static const bg = Color(0xFFF1F6FD);
  static const ink = Color(0xFF111827);
  static const mute = Color(0xFF6B7280);
  static const line = Color(0xFFE5E7EB);
  static const green = Color(0xFF15803D);
  static const greenBg = Color(0xFFDCFCE7);
  static const amber = Color(0xFFB45309);
  static const amberBg = Color(0xFFFEF3C7);
  static const red = Color(0xFFB91C1C);
  static const redBg = Color(0xFFFEE2E2);
  static const violet = Color(0xFF6D28D9);
  static const violetBg = Color(0xFFEDE9FE);
  static const grey = Color(0xFF4B5563);
  static const greyBg = Color(0xFFF3F4F6);
}

({Color fg, Color bg}) statusColors(AttStatus s) => switch (s) {
      AttStatus.hadir => (fg: C.green, bg: C.greenBg),
      AttStatus.terlambat => (fg: C.amber, bg: C.amberBg),
      AttStatus.izin => (fg: C.blue, bg: const Color(0xFFDBEAFE)),
      AttStatus.sakit => (fg: C.violet, bg: C.violetBg),
      AttStatus.alpha => (fg: C.red, bg: C.redBg),
      AttStatus.dispen => (fg: C.grey, bg: C.greyBg),
    };

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: C.blue, surface: Colors.white);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.blue, width: 1.5),
      ),
    ),
  );
}
