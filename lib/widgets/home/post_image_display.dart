import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/api_client.dart';

/// Shared image loader for posts and merchandise: network (incl. resolved API paths), data URIs, local files.
class PostImageDisplay extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Widget Function()? placeholder;

  const PostImageDisplay({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return placeholder?.call() ?? _defaultPlaceholder();
    }
    if (url.startsWith('data:image')) {
      final i = url.indexOf(',');
      if (i < 0) return placeholder?.call() ?? _defaultPlaceholder();
      try {
        final bytes = base64Decode(url.substring(i + 1));
        return Image.memory(bytes, fit: fit, errorBuilder: (_, __, ___) => placeholder?.call() ?? _defaultPlaceholder());
      } catch (_) {
        return placeholder?.call() ?? _defaultPlaceholder();
      }
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder?.call() ?? _defaultPlaceholder(),
      );
    }
    // Camera / gallery paths must be checked before [resolveMediaUrl], which would
    // turn "/data/..." into a bogus http URL and break [Image.network].
    try {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder?.call() ?? _defaultPlaceholder(),
        );
      }
    } catch (_) {
      // Invalid path (e.g. some URI schemes); fall through to API-relative URL.
    }
    final resolved = ApiClient.resolveMediaUrl(url);
    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return Image.network(
        resolved,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder?.call() ?? _defaultPlaceholder(),
      );
    }
    return placeholder?.call() ?? _defaultPlaceholder();
  }

  Widget _defaultPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD8CAD9),
            Color(0xFFC7C7D9),
            Color(0xFFE2E2EA),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 38, color: Colors.black45),
      ),
    );
  }
}
