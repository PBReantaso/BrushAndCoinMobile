import 'package:flutter/material.dart';

import '../../screens/search/search_screen.dart';

class BcAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BcAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFEDEDF1),
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
              children: [
                TextSpan(text: 'B', style: TextStyle(color: Colors.black)),
                TextSpan(text: '&', style: TextStyle(color: Colors.black)),
                TextSpan(text: 'C', style: TextStyle(color: Color(0xFFFF4A4A))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const SearchScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 18, color: Color(0xFF8B8B8B)),
                      const SizedBox(width: 6),
                      Text(
                        'Search',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8B8B8B),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications,
              color: Color(0xFF101010),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const Icon(
              Icons.settings,
              color: Color(0xFF101010),
            ),
          ),
        ],
      ),
    );
  }
}

