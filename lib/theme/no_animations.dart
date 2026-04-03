import 'package:flutter/material.dart';

/// Page transition that swaps routes with no motion (used with [PageTransitionsTheme]).
class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

PageTransitionsTheme buildNoPageTransitionsTheme() {
  return PageTransitionsTheme(
    builders: {
      for (final TargetPlatform p in TargetPlatform.values)
        p: const NoTransitionsBuilder(),
    },
  );
}
