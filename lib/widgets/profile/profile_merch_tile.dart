import 'package:flutter/material.dart';

import '../home/post_image_display.dart';

/// Square grid cell for profile merchandise — same layout as gallery tiles.
class ProfileMerchTile extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;

  const ProfileMerchTile({
    super.key,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox.expand(
            child: PostImageDisplay(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: _merchFallback,
            ),
          ),
        ),
      ),
    );
  }

  Widget _merchFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A3728), Color(0xFFC4A57B)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 32),
      ),
    );
  }
}
