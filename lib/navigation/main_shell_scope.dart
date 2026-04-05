import 'package:flutter/material.dart';

/// Provided by [MainShell] so the header logo can switch the bottom-nav tab.
class MainShellScope extends InheritedWidget {
  const MainShellScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  final ValueChanged<int> selectTab;

  static MainShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>();
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) => false;
}
