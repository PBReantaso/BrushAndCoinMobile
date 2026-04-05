import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchUser {
  final int id;
  final String username;
  /// From search/API when available; used for list thumbnails.
  final String? avatarUrl;

  const RecentSearchUser({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'id': id, 'username': username};
    final a = avatarUrl?.trim();
    if (a != null && a.isNotEmpty) m['avatarUrl'] = a;
    return m;
  }

  factory RecentSearchUser.fromJson(Map<String, dynamic> json) {
    final au = json['avatarUrl'];
    final url = au is String ? au.trim() : (au != null ? '$au'.trim() : '');
    return RecentSearchUser(
      id: _readInt(json['id']),
      username: (json['username'] as String?)?.trim() ?? '',
      avatarUrl: url.isEmpty ? null : url,
    );
  }

  bool get isValid => id > 0 && username.isNotEmpty;
}

/// Tags, raw search queries, and opened profiles — ordered: tags, then queries, then users.
/// Persisted per logged-in user.
class RecentSearchSnapshot {
  final List<String> tags;
  final List<String> queries;
  final List<RecentSearchUser> users;

  const RecentSearchSnapshot({
    required this.tags,
    required this.queries,
    required this.users,
  });

  static const empty = RecentSearchSnapshot(tags: [], queries: [], users: []);

  bool get isEmpty => tags.isEmpty && queries.isEmpty && users.isEmpty;

  Map<String, dynamic> toJson() => {
        'tags': tags,
        'queries': queries,
        'users': users.map((e) => e.toJson()).toList(),
      };

  factory RecentSearchSnapshot.fromJson(Map<String, dynamic> json) {
    final tags = (json['tags'] is List)
        ? (json['tags'] as List).map((e) => '$e'.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];
    final queries = (json['queries'] is List)
        ? (json['queries'] as List).map((e) => '$e'.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];
    final usersRaw = json['users'];
    final users = usersRaw is List
        ? usersRaw
            .whereType<Map>()
            .map((e) => RecentSearchUser.fromJson(e.map((k, v) => MapEntry('$k', v))))
            .where((e) => e.isValid)
            .toList()
        : <RecentSearchUser>[];
    return RecentSearchSnapshot(tags: tags, queries: queries, users: users);
  }
}

int _readInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class RecentSearchesStorage {
  RecentSearchesStorage._();

  static const _legacyKey = 'bc_recent_user_searches_v1';
  static const _maxTags = 15;
  static const _maxQueries = 15;
  static const _maxUsers = 20;

  static String _keyForUser(int? userId) {
    if (userId != null && userId > 0) {
      return 'bc_recent_searches_v3_u$userId';
    }
    return 'bc_recent_searches_v3_guest';
  }

  static Future<RecentSearchSnapshot> loadSnapshot(int? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForUser(userId);
    var raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      if (userId != null && userId > 0) {
        raw = prefs.getString(_legacyKey);
        if (raw != null && raw.isNotEmpty) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is List) {
              final users = decoded
                  .whereType<Map>()
                  .map((e) => RecentSearchUser.fromJson(e.map((k, v) => MapEntry('$k', v))))
                  .where((e) => e.isValid)
                  .toList();
              final snap = RecentSearchSnapshot(tags: [], queries: [], users: users);
              await _writeSnapshot(prefs, key, snap);
              await prefs.remove(_legacyKey);
              return snap;
            }
          } catch (_) {}
        }
      }
      return RecentSearchSnapshot.empty;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return RecentSearchSnapshot.fromJson(decoded.map((k, v) => MapEntry('$k', v)));
      }
    } catch (_) {}
    return RecentSearchSnapshot.empty;
  }

  static Future<void> _writeSnapshot(
    SharedPreferences prefs,
    String key,
    RecentSearchSnapshot snap,
  ) async {
    await prefs.setString(key, jsonEncode(snap.toJson()));
  }

  static Future<void> _save(int? userId, RecentSearchSnapshot snap) async {
    final prefs = await SharedPreferences.getInstance();
    await _writeSnapshot(prefs, _keyForUser(userId), snap);
  }

  static Future<void> addTag(int? userId, String tag) async {
    final t = tag.trim().replaceFirst(RegExp(r'^#'), '');
    if (t.isEmpty) return;
    final lower = t.toLowerCase();
    final snap = await loadSnapshot(userId);
    final rest = snap.tags.where((x) => x.toLowerCase() != lower).toList();
    rest.insert(0, t);
    await _save(
      userId,
      RecentSearchSnapshot(
        tags: rest.take(_maxTags).toList(),
        queries: snap.queries,
        users: snap.users,
      ),
    );
  }

  static Future<void> addQuery(int? userId, String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final snap = await loadSnapshot(userId);
    final lower = q.toLowerCase();
    final rest = snap.queries.where((x) => x.toLowerCase() != lower).toList();
    rest.insert(0, q);
    await _save(
      userId,
      RecentSearchSnapshot(
        tags: snap.tags,
        queries: rest.take(_maxQueries).toList(),
        users: snap.users,
      ),
    );
  }

  static Future<void> addUser(int? userId, RecentSearchUser user) async {
    if (!user.isValid) return;
    final snap = await loadSnapshot(userId);
    final filtered = snap.users.where((e) => e.id != user.id).toList();
    filtered.insert(0, user);
    await _save(
      userId,
      RecentSearchSnapshot(
        tags: snap.tags,
        queries: snap.queries,
        users: filtered.take(_maxUsers).toList(),
      ),
    );
  }

  /// Sets [avatarUrl] for an existing recent profile without changing list order.
  static Future<void> updateUserAvatar(
    int? userId,
    int profileUserId,
    String avatarUrl,
  ) async {
    final a = avatarUrl.trim();
    if (a.isEmpty) return;
    final snap = await loadSnapshot(userId);
    final idx = snap.users.indexWhere((e) => e.id == profileUserId);
    if (idx < 0) return;
    final u = snap.users[idx];
    if (u.avatarUrl == a) return;
    final next = List<RecentSearchUser>.from(snap.users);
    next[idx] = RecentSearchUser(id: u.id, username: u.username, avatarUrl: a);
    await _save(
      userId,
      RecentSearchSnapshot(
        tags: snap.tags,
        queries: snap.queries,
        users: next,
      ),
    );
  }

  static Future<void> removeTag(int? userId, String tag) async {
    final lower = tag.trim().replaceFirst(RegExp(r'^#'), '').toLowerCase();
    if (lower.isEmpty) return;
    final snap = await loadSnapshot(userId);
    await _save(
      userId,
      RecentSearchSnapshot(
        tags: snap.tags.where((x) => x.toLowerCase() != lower).toList(),
        queries: snap.queries,
        users: snap.users,
      ),
    );
  }

  static Future<void> removeQuery(int? userId, String query) async {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return;
    final snap = await loadSnapshot(userId);
    await _save(
      userId,
      RecentSearchSnapshot(
        tags: snap.tags,
        queries: snap.queries.where((x) => x.toLowerCase() != lower).toList(),
        users: snap.users,
      ),
    );
  }

  static Future<void> removeUser(int? userId, int profileUserId) async {
    final snap = await loadSnapshot(userId);
    await _save(
      userId,
      RecentSearchSnapshot(
        tags: snap.tags,
        queries: snap.queries,
        users: snap.users.where((e) => e.id != profileUserId).toList(),
      ),
    );
  }

  static Future<void> clear(int? userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyForUser(userId));
  }
}
