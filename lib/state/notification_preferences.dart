import 'package:shared_preferences/shared_preferences.dart';

/// Keys for on-device notification category preferences (future: push routing).
abstract final class NotificationPrefKeys {
  static const master = 'notif_master';
  static const messages = 'notif_messages';
  static const mentions = 'notif_mentions';
  static const commissions = 'notif_commissions';
  static const events = 'notif_events';
  static const social = 'notif_social';
  static const system = 'notif_system';
}

Future<Map<String, bool>> loadNotificationPrefs() async {
  final p = await SharedPreferences.getInstance();
  bool g(String k, bool d) => p.getBool(k) ?? d;

  return {
    NotificationPrefKeys.master: g(NotificationPrefKeys.master, true),
    NotificationPrefKeys.messages: g(NotificationPrefKeys.messages, true),
    NotificationPrefKeys.mentions: g(NotificationPrefKeys.mentions, true),
    NotificationPrefKeys.commissions: g(NotificationPrefKeys.commissions, true),
    NotificationPrefKeys.events: g(NotificationPrefKeys.events, true),
    NotificationPrefKeys.social: g(NotificationPrefKeys.social, true),
    NotificationPrefKeys.system: g(NotificationPrefKeys.system, true),
  };
}

Future<void> saveNotificationPref(String key, bool value) async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(key, value);
}
