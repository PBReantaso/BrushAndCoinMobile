import 'package:flutter/material.dart';

/// Single typography scale for the app. Use via [Theme.of(context).textTheme]:
/// - [TextTheme.headlineMedium] — auth hero titles
/// - [TextTheme.headlineSmall] — large section titles (e.g. form heroes)
/// - [TextTheme.displaySmall] — large numeric / hero accents (e.g. event day digit)
/// - [TextTheme.titleLarge] — app bars, primary brand row
/// - [TextTheme.titleMedium] — section / field group headers
/// - [TextTheme.titleSmall] — emphasized secondary lines, labels
/// - [TextTheme.bodyLarge] — primary body
/// - [TextTheme.bodyMedium] — secondary body
/// - [TextTheme.bodySmall] — captions, hints, metadata
/// - [TextTheme.labelSmall] — chips, tiny labels
TextTheme buildAppTextTheme() {
  const ink = Color(0xFF222222);
  const inkStrong = Color(0xFF1F1F24);
  const inkSoft = Color(0xFF2C2C31);
  const inkMuted = Color(0xFF6A6A73);

  return TextTheme(
    displaySmall: const TextStyle(
      fontSize: 40,
      height: 1,
      fontWeight: FontWeight.w900,
      color: Colors.black,
    ),
    headlineMedium: const TextStyle(
      fontSize: 32,
      height: 1.1,
      fontWeight: FontWeight.w800,
      color: inkStrong,
    ),
    headlineSmall: const TextStyle(
      fontSize: 28,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: Color(0xFF222228),
    ),
    titleLarge: const TextStyle(
      fontSize: 22,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: inkStrong,
      letterSpacing: 0.2,
    ),
    titleMedium: const TextStyle(
      fontSize: 17,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: inkSoft,
    ),
    titleSmall: const TextStyle(
      fontSize: 14,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: inkSoft,
    ),
    bodyLarge: const TextStyle(
      fontSize: 15,
      height: 1.45,
      fontWeight: FontWeight.w400,
      color: ink,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      height: 1.45,
      fontWeight: FontWeight.w400,
      color: ink,
    ),
    bodySmall: const TextStyle(
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: inkMuted,
    ),
    labelLarge: const TextStyle(
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    labelSmall: const TextStyle(
      fontSize: 11,
      height: 1.25,
      fontWeight: FontWeight.w500,
      color: Color(0xFF2B2B31),
    ),
  );
}
