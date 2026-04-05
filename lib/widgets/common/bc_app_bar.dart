import 'package:flutter/material.dart';

import '../../navigation/main_shell_scope.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../state/inbox_badge_scope.dart';

class BcAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BcAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final logoBase = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ) ??
        const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        );
    return AppBar(
      backgroundColor: const Color(0xFFFFFFFF),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                MainShellScope.maybeOf(context)?.selectTab(0);
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: RichText(
                  text: TextSpan(
                    style: logoBase,
                    children: [
                      const TextSpan(text: 'B', style: TextStyle(color: Colors.black)),
                      const TextSpan(text: '&', style: TextStyle(color: Colors.black)),
                      TextSpan(
                        text: 'C',
                        style: logoBase.copyWith(color: const Color(0xFFFF4A4A)),
                      ),
                    ],
                  ),
                ),
              ),
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
                    color: const Color(0xFFF3F3F6),
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
          Builder(
            builder: (context) {
              final ctrl = InboxBadgeScope.maybeOf(context);
              const baseIcon = Icon(
                Icons.notifications,
                color: Color(0xFF101010),
              );
              Widget bellIcon(int n) {
                if (n <= 0) return baseIcon;
                return Badge(
                  label: Text(
                    n > 99 ? '99+' : '$n',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  backgroundColor: const Color(0xFFFF4A4A),
                  textColor: Colors.white,
                  child: baseIcon,
                );
              }

              if (ctrl == null) {
                return IconButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  icon: baseIcon,
                );
              }

              return ListenableBuilder(
                listenable: ctrl,
                builder: (context, _) {
                  return IconButton(
                    onPressed: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                      ctrl.refresh();
                    },
                    icon: bellIcon(ctrl.notificationUnread),
                  );
                },
              );
            },
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

