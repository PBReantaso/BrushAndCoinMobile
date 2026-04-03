import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';

class AuthColors {
  static const primaryRed = Color(0xFFFF3B30);
  static const hintGray = Color(0xFFBDBDBD);
  static const borderGray = Color(0xFFBDBDBD);
  static const linkBlue = Color(0xFF2F80ED);
}

class AuthTextStyles {
  static TextStyle get headlineRed => buildAppTextTheme().headlineMedium!.copyWith(
        color: AuthColors.primaryRed,
      );

  static TextStyle get headlineBlack => buildAppTextTheme().headlineMedium!.copyWith(
        color: Colors.black,
      );

  static TextStyle get fieldLabel => buildAppTextTheme().titleSmall!.copyWith(
        color: Colors.black,
      );
}

InputDecoration authInputDecoration({
  required String hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: buildAppTextTheme().bodySmall?.copyWith(
      color: AuthColors.hintGray,
      fontWeight: FontWeight.w400,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AuthColors.borderGray, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AuthColors.borderGray, width: 1),
    ),
    suffixIcon: suffixIcon,
  );
}

ButtonStyle primaryPillButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: AuthColors.primaryRed,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    ),
    minimumSize: const Size.fromHeight(48),
    textStyle: buildAppTextTheme().bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );
}

ButtonStyle outlinedPillButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    ),
    side: const BorderSide(color: AuthColors.borderGray, width: 1),
    minimumSize: const Size.fromHeight(48),
    textStyle: buildAppTextTheme().bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    ),
  );
}

