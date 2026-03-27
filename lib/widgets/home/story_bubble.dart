import 'package:flutter/material.dart';

class StoryBubble extends StatelessWidget {
  final String label;
  final String initials;
  final VoidCallback? onTap;

  const StoryBubble({
    super.key,
    required this.label,
    required this.initials,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFBDBDBD),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF2B2B2B),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

