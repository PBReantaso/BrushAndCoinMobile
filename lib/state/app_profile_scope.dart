import 'package:flutter/widgets.dart';

import 'app_profile.dart';

class AppProfileScope extends InheritedNotifier<AppProfileState> {
  const AppProfileScope({
    super.key,
    required AppProfileState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppProfileState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppProfileScope>();
    assert(scope != null, 'AppProfileScope not found in widget tree');
    return scope!.notifier!;
  }
}

