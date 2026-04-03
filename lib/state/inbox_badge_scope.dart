import 'package:flutter/widgets.dart';

import '../services/api_client.dart';

/// Holds unread counts for the notification bell and Messages tab; refresh after reads or on a timer.
class InboxBadgeController extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  int notificationUnread = 0;
  int messageUnread = 0;

  Future<void> refresh() async {
    try {
      final results = await Future.wait([
        _api.fetchUnreadNotificationCount(),
        _api.fetchUnreadMessageCount(),
      ]);
      final n = results[0];
      final m = results[1];
      if (notificationUnread != n || messageUnread != m) {
        notificationUnread = n;
        messageUnread = m;
        notifyListeners();
      }
    } catch (_) {
      // Keep previous counts on network errors.
    }
  }
}

class InboxBadgeScope extends InheritedNotifier<InboxBadgeController> {
  const InboxBadgeScope({
    super.key,
    required InboxBadgeController super.notifier,
    required super.child,
  });

  static InboxBadgeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<InboxBadgeScope>();
    assert(scope != null, 'InboxBadgeScope not found');
    return scope!.notifier!;
  }

  static InboxBadgeController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InboxBadgeScope>()?.notifier;
  }
}
