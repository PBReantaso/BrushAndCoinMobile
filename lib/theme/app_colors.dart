import 'package:flutter/material.dart';

/// Shared UI tokens (matches [MaterialApp] scaffold + commission/chat polish).
abstract final class BcColors {
  static const Color pageBackground = Color(0xFFF3F3F6);
  static const Color cardBorder = Color(0xFFE6E6EA);
  static const Color brandRed = Color(0xFFFF4A4A);
  static const Color ink = Color(0xFF1F1F24);
  static const Color labelMuted = Color(0xFF8C8C90);
  static const Color body = Color(0xFF1A1A1E);
  static const Color subtitle = Color(0xFF6E6E6E);
}

/// Title on secondary screens (commission detail, chat, etc.).
TextStyle? bcPushedScreenTitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: BcColors.brandRed,
      );
}

/// Hairline under pushed-screen app bars (commission / chat pattern).
class BcAppBarBottomLine extends StatelessWidget implements PreferredSizeWidget {
  const BcAppBarBottomLine({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(1);

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: BcColors.cardBorder,
    );
  }
}
