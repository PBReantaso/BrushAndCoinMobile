import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_role_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/calendar_map_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/home/messages_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'state/app_profile.dart';
import 'state/app_profile_scope.dart';

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
  runApp(const BrushAndCoinApp());
}

class BrushAndCoinApp extends StatelessWidget {
  const BrushAndCoinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProfileScope(
      notifier: AppProfileState(),
      child: MaterialApp(
        title: 'Brush&Coin',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const NoStretchScrollBehavior(),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
          ),
          scaffoldBackgroundColor: const Color(0xFFF3F3F6),
          navigationBarTheme: NavigationBarThemeData(
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: isSelected ? const Color(0xFFFF4A4A) : const Color(0xFF222222),
                size: 22,
              );
            }),
          ),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignUpScreen(),
          '/onboarding': (_) => const OnboardingRoleScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/app': (_) => const MainShell(),
        },
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

  final _pages = const [
    DashboardScreen(),
    CalendarMapScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isHome = _currentIndex == 0;
    return Scaffold(
      body: Stack(
        children: [
          _pages[_currentIndex],
          if (isHome)
            Positioned(
              right: 18,
              // Slightly above the bottom nav bar.
              bottom: 25,
              child: SizedBox(
                width: 58,
                height: 58,
                child: FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: const Color(0xFFFF4A4A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFFEDEDF1),
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF222222),
          );
        }),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Calendar & Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

