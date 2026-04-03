import 'dart:convert';

import 'package:flutter/material.dart';

/// Profile photo from HTTPS URL or inline `data:image/...;base64,...`.
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData placeholderIcon;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 44,
    this.placeholderIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    final u = imageUrl?.trim() ?? '';
    if (u.isEmpty) {
      return _placeholder();
    }
    if (u.startsWith('data:image')) {
      final i = u.indexOf(',');
      if (i < 0) return _placeholder();
      try {
        final bytes = base64Decode(u.substring(i + 1));
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {
        return _placeholder();
      }
    }
    if (u.startsWith('http://') || u.startsWith('https://')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFD8D8DE),
        backgroundImage: NetworkImage(u),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFD8D8DE),
      child: Icon(placeholderIcon, color: const Color(0xFF6D6D75), size: radius * 0.77),
    );
  }
}
