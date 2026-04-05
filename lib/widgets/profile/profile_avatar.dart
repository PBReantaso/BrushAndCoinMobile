import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_client.dart';

/// Profile photo from HTTPS URL, API-relative path, or inline `data:image/...;base64,...`.
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData placeholderIcon;
  final Color? placeholderBackgroundColor;
  final Color? placeholderIconColor;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 44,
    this.placeholderIcon = Icons.person,
    this.placeholderBackgroundColor,
    this.placeholderIconColor,
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

    final resolved = ApiClient.resolveMediaUrl(u);
    if (resolved.isEmpty ||
        (!resolved.startsWith('http://') && !resolved.startsWith('https://'))) {
      return _placeholder();
    }

    final d = radius * 2;
    return ClipOval(
      child: Image.network(
        resolved,
        width: d,
        height: d,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: d,
            height: d,
            child: Center(
              child: SizedBox(
                width: radius * 0.9,
                height: radius * 0.9,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: placeholderBackgroundColor ?? const Color(0xFFFF4A4A),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: placeholderBackgroundColor ?? const Color(0xFFD8D8DE),
      child: Icon(
        placeholderIcon,
        color: placeholderIconColor ?? const Color(0xFF6D6D75),
        size: radius * 0.77,
      ),
    );
  }
}
