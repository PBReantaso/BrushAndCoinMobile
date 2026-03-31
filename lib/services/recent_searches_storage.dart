import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchUser {
  final int id;
  final String username;

  const RecentSearchUser({required this.id, required this.username});

  Map<String, dynamic> toJson() => {'id': id, 'username': username};

  factory RecentSearchUser.fromJson(Map<String, dynamic> json) {
    return RecentSearchUser(
      id: _readInt(json['id']),
      username: (json['username'] as String?)?.trim() ?? '',
    );
  }

  bool get isValid => id > 0 && username.isNotEmpty;
}

int _readInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class RecentSearchesStorage {
  RecentSearchesStorage._();
  static const _key = 'bc_recent_user_searches_v1';
  static const _maxItems = 20;

  static Future<List<RecentSearchUser>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => RecentSearchUser.fromJson(e.map((k, v) => MapEntry('$k', v))))
          .where((e) => e.isValid)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _write(List<RecentSearchUser> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  /// Adds or moves user to the front; caps at [_maxItems].
  static Future<void> add(RecentSearchUser user) async {
    if (!user.isValid) return;
    final list = await load();
    final filtered = list.where((e) => e.id != user.id).toList();
    filtered.insert(0, user);
    await _write(filtered.take(_maxItems).toList());
  }

  static Future<void> remove(int userId) async {
    final list = await load();
    await _write(list.where((e) => e.id != userId).toList());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
