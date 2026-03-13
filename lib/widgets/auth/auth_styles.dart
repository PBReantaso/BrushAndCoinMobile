import 'package:flutter/material.dart';

class AuthColors {
  static const primaryRed = Color(0xFFFF3B30);
  static const hintGray = Color(0xFFBDBDBD);
  static const borderGray = Color(0xFFBDBDBD);
  static const linkBlue = Color(0xFF2F80ED);
}

class AuthTextStyles {
  static const headlineRed = TextStyle(
    fontSize: 36,
    height: 1.05,
    fontWeight: FontWeight.w800,
    color: AuthColors.primaryRed,
  );

  static const headlineBlack = TextStyle(
    fontSize: 36,
    height: 1.05,
    fontWeight: FontWeight.w800,
    color: Colors.black,
  );

  static const fieldLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );
}

InputDecoration authInputDecoration({
  required String hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: AuthColors.hintGray,
      fontSize: 12,
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
    textStyle: const TextStyle(
      fontSize: 14,
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
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );
}

