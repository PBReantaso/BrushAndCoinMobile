import 'package:flutter/material.dart';

/// Username row with a lock icon when the account is set to private.
class UsernameWithPrivateLock extends StatelessWidget {
  final String username;
  final bool isPrivate;
  final TextStyle? textStyle;
  final double lockSize;

  const UsernameWithPrivateLock({
    super.key,
    required this.username,
    required this.isPrivate,
    this.textStyle,
    this.lockSize = 18,
  });

  static const Color _lockColor = Color(0xFF6C6C74);

  @override
  Widget build(BuildContext context) {
    final style = textStyle ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1E),
            );
    return Row(
      children: [
        Expanded(
          child: Text(
            username,
            style: style,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (isPrivate) ...[
          SizedBox(width: lockSize >= 18 ? 6 : 5),
          Icon(Icons.lock_outline, size: lockSize, color: _lockColor),
        ],
      ],
    );
  }
}
