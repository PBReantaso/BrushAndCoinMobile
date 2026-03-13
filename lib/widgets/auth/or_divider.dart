import 'package:flutter/material.dart';

import 'auth_styles.dart';

class OrDivider extends StatelessWidget {
  final String text;

  const OrDivider({super.key, this.text = 'Or'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(thickness: 1, color: AuthColors.borderGray),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        const Expanded(
          child: Divider(thickness: 1, color: AuthColors.borderGray),
        ),
      ],
    );
  }
}

