import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'navigation/app_route_observer.dart';
import 'navigation/main_shell_scope.dart';
import 'theme/app_typography.dart';
import 'theme/no_animations.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_role_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/communication/communication_screen.dart';
import 'screens/home/calendar_map_screen.dart';
import 'screens/home/create_event_screen.dart';
import 'screens/home/create_post_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/api_client.dart';
import 'services/push_device_registration.dart';
import 'state/app_profile.dart';
import 'state/app_profile_scope.dart';
import 'state/inbox_badge_scope.dart';

class NoStretchScrollBehavior extends MaterialScrollBehavior {
  const NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Remove the stretch/glow effect on all scrollables.
    return child;
  }
}

void main() {
  tz.initializeTimeZones();
  runApp(const BrushAndCoinApp());
}

class BrushAndCoinApp extends StatefulWidget {
  const BrushAndCoinApp({super.key});

  @override
  State<BrushAndCoinApp> createState() => _BrushAndCoinAppState();
}

class _BrushAndCoinAppState extends State<BrushAndCoinApp> with WidgetsBindingObserver {
  late final InboxBadgeController _inboxBadges = InboxBadgeController();
  Timer? _inboxBadgeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inboxBadges.refresh();
    _inboxBadgeTimer = Timer.periodic(const Duration(seconds: 45), (_) => _inboxBadges.refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inboxBadgeTimer?.cancel();
    _inboxBadges.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _inboxBadges.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = buildAppTextTheme();
    return AppProfileScope(
      notifier: AppProfileState(),
      child: InboxBadgeScope(
        notifier: _inboxBadges,
        child: MaterialApp(
        title: 'Brush&Coin',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const NoStretchScrollBehavior(),
        themeAnimationStyle: AnimationStyle.noAnimation,
        builder: (context, child) {
          return child ?? const SizedBox.shrink();
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
          ),
          scaffoldBackgroundColor: const Color(0xFFF3F3F6),
          textTheme: textTheme,
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFFFFFFFF),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleTextStyle: textTheme.titleLarge,
            iconTheme: const IconThemeData(color: Color(0xFF1F1F24)),
            foregroundColor: const Color(0xFF1F1F24),
          ),
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: textTheme.bodySmall?.copyWith(
              color: const Color(0xFF7C7C85),
              fontWeight: FontWeight.w400,
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFFFFFFFF),
            contentTextStyle: textTheme.bodyMedium?.copyWith(color: const Color(0xFF222222)),
            actionTextColor: const Color(0xFFFF4A4A),
            elevation: 2,
            behavior: SnackBarBehavior.floating,
          ),
          pageTransitionsTheme: buildNoPageTransitionsTheme(),
          splashFactory: NoSplash.splashFactory,
          navigationBarTheme: NavigationBarThemeData(
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: isSelected ? const Color(0xFFFF4A4A) : const Color(0xFF222222),
                size: 22,
              );
            }),
            backgroundColor: const Color(0xFFFFFFFF),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return (textTheme.bodySmall ?? const TextStyle()).copyWith(
                color: const Color(0xFF222222),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              );
            }),
          ),
          useMaterial3: true,
        ),
        navigatorObservers: [appRouteObserver],
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignUpScreen(),
          '/onboarding': (_) => const OnboardingRoleScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/app': (_) => const MainShell(),
        },
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _calendarRefreshTick = 0;
  int _homeRefreshTick = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      trySyncPushDeviceAfterLogin(ApiClient());
    });
  }

  List<Widget> get _pages => [
        DashboardScreen(key: ValueKey(_homeRefreshTick)),
        CalendarMapScreen(key: ValueKey(_calendarRefreshTick)),
        const CommunicationScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final isHome = _currentIndex == 0;
    final isCalendar = _currentIndex == 1;
    final inbox = InboxBadgeScope.of(context);
    return MainShellScope(
      selectTab: (index) {
        setState(() {
          _currentIndex = index;
        });
        inbox.refresh();
      },
      child: Scaffold(
        body: Stack(
          children: [
            _pages[_currentIndex],
            if (isHome || isCalendar)
              Positioned(
                right: 18,
                // Slightly above the bottom nav bar.
                bottom: 25,
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: FloatingActionButton(
                    onPressed: () async {
                      if (_currentIndex == 0) {
                        final created = await showCreatePostBottomSheet(context);
                        if (created == true && mounted) {
                          setState(() {
                            _homeRefreshTick++;
                          });
                        }
                        return;
                      }
                      if (_currentIndex == 1) {
                        final created = await showCreateEventBottomSheet(context);
                        if (created == true && mounted) {
                          setState(() {
                            _calendarRefreshTick++;
                          });
                        }
                      }
                    },
                    backgroundColor: const Color(0xFFFF4A4A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add, size: 24),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: inbox,
          builder: (context, _) {
            final msgCount = inbox.messageUnread;
            return NavigationBar(
              animationDuration: Duration.zero,
              backgroundColor: const Color(0xFFFFFFFF),
              indicatorColor: Colors.transparent,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
                inbox.refresh();
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Calendar & Map',
                ),
                NavigationDestination(
                  icon: _navBadgeIcon(
                    count: msgCount,
                    outlined: Icons.chat_bubble_outline,
                    filled: Icons.chat_bubble,
                    selected: false,
                  ),
                  selectedIcon: _navBadgeIcon(
                    count: msgCount,
                    outlined: Icons.chat_bubble_outline,
                    filled: Icons.chat_bubble,
                    selected: true,
                  ),
                  label: 'Messages',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Widget _navBadgeIcon({
  required int count,
  required IconData outlined,
  required IconData filled,
  required bool selected,
}) {
  final icon = Icon(selected ? filled : outlined);
  if (count <= 0) return icon;
  final label = count > 99 ? '99+' : '$count';
  return Badge(
    label: Text(
      label,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    backgroundColor: const Color(0xFFFF4A4A),
    textColor: Colors.white,
    child: icon,
  );
}

