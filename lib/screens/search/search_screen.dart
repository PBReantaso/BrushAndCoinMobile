import 'dart:async';

import 'package:flutter/material.dart';

import '../../navigation/user_profile_navigation.dart';
import '../../theme/app_colors.dart';
import '../../theme/content_spacing.dart';
import '../../services/api_client.dart';
import '../../services/recent_searches_storage.dart';
import '../../widgets/profile/profile_avatar.dart';
import 'tagged_posts_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ApiClient();
  final _controller = TextEditingController();
  Timer? _debounce;
  RecentSearchSnapshot _recent = RecentSearchSnapshot.empty;
  List<_SearchHit> _results = [];
  bool _loadingRecent = true;
  bool _loadingSearch = false;
  String? _searchError;
  bool _enrichingRecentAvatars = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final uid = await _api.getCurrentUserId();
    final snap = await RecentSearchesStorage.loadSnapshot(uid);
    if (!mounted) return;
    setState(() {
      _recent = snap;
      _loadingRecent = false;
    });
    unawaited(_enrichRecentProfileAvatars(uid));
  }

  /// Fills missing profile photos for stored recents (legacy rows or older saves).
  Future<void> _enrichRecentProfileAvatars(int? uid) async {
    if (_enrichingRecentAvatars) return;
    final needAvatar = _recent.users
        .where((u) => (u.avatarUrl == null || u.avatarUrl!.trim().isEmpty))
        .toList();
    if (needAvatar.isEmpty) return;
    _enrichingRecentAvatars = true;
    var changed = false;
    try {
      for (final u in needAvatar) {
        if (!mounted) break;
        try {
          final json = await _api.fetchPublicUser(u.id);
          final url = _parseAvatarUrlFromProfileJson(json);
          if (url == null) continue;
          await RecentSearchesStorage.updateUserAvatar(uid, u.id, url);
          changed = true;
        } catch (_) {}
      }
      if (changed && mounted) {
        final snap = await RecentSearchesStorage.loadSnapshot(uid);
        if (!mounted) return;
        setState(() => _recent = snap);
      }
    } finally {
      _enrichingRecentAvatars = false;
    }
  }

  static String? _parseAvatarUrlFromProfileJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map) return null;
    final raw = user['avatarUrl'] ?? user['avatar_url'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final q = value.trim();
      if (!mounted) return;
      if (q.isEmpty) {
        setState(() {
          _results = [];
          _loadingSearch = false;
          _searchError = null;
        });
        return;
      }
      _runSearch(q);
    });
  }

  Future<void> _runSearch(String q) async {
    setState(() {
      _loadingSearch = true;
      _searchError = null;
    });
    try {
      final raw = await _api.searchUsers(q);
      if (!mounted) return;
      setState(() {
        _results = raw.map(_SearchHit.fromJson).where((e) => e.id > 0).toList();
      });
      final uid = await _api.getCurrentUserId();
      await RecentSearchesStorage.addQuery(uid, q);
      if (mounted) await _loadRecent();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = e.message;
        _results = [];
      });
    } finally {
      if (mounted) setState(() => _loadingSearch = false);
    }
  }

  void _openUser(RecentSearchUser user) {
    if (user.id <= 0) return;
    final hint = user.username.trim().isNotEmpty ? user.username.trim() : 'User';
    pushUserProfile(context, userId: user.id, username: hint);
    () async {
      final uid = await _api.getCurrentUserId();
      var avatar = user.avatarUrl?.trim();
      if (avatar == null || avatar.isEmpty) {
        try {
          final json = await _api.fetchPublicUser(user.id);
          avatar = _parseAvatarUrlFromProfileJson(json);
        } catch (_) {}
      }
      await RecentSearchesStorage.addUser(
        uid,
        RecentSearchUser(id: user.id, username: hint, avatarUrl: avatar),
      );
      if (mounted) await _loadRecent();
    }();
  }

  Future<void> _removeRecentTag(String tag) async {
    final uid = await _api.getCurrentUserId();
    await RecentSearchesStorage.removeTag(uid, tag);
    await _loadRecent();
  }

  Future<void> _removeRecentQuery(String query) async {
    final uid = await _api.getCurrentUserId();
    await RecentSearchesStorage.removeQuery(uid, query);
    await _loadRecent();
  }

  Future<void> _removeRecentUser(int profileUserId) async {
    final uid = await _api.getCurrentUserId();
    await RecentSearchesStorage.removeUser(uid, profileUserId);
    await _loadRecent();
  }

  Future<void> _clearRecent() async {
    final uid = await _api.getCurrentUserId();
    await RecentSearchesStorage.clear(uid);
    await _loadRecent();
  }

  @override
  Widget build(BuildContext context) {
    final showRecent = _controller.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: BcColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: const BackButton(color: BcColors.ink),
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: Theme.of(context).textTheme.titleMedium,
          decoration: const InputDecoration(
            hintText: 'Search',
            border: InputBorder.none,
            isDense: true,
          ),
          onChanged: (v) {
            setState(() {});
            _onQueryChanged(v);
          },
        ),
        bottom: const BcAppBarBottomLine(),
      ),
      body: showRecent
          ? _buildRecentBody()
          : _buildResultsBody(),
    );
  }

  void _applyRecentQuery(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    setState(() {});
    _onQueryChanged(q);
  }

  Widget _buildRecentBody() {
    if (_loadingRecent) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recent.isEmpty) {
      return Center(
        child: Text(
          'No recent searches.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6C6C74),
                fontWeight: FontWeight.w400,
              ),
        ),
      );
    }
    final tags = _recent.tags;
    final queries = _recent.queries;
    final users = _recent.users;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kScreenHorizontalPadding,
            12,
            kScreenHorizontalPadding,
            8,
          ),
          child: Row(
            children: [
              Text(
                'Recent',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1E),
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearRecent,
                child: const Text('Clear all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: _recentListRows(
              context,
              tags: tags,
              queries: queries,
              users: users,
            ),
          ),
        ),
      ],
    );
  }

  static const _rowPadding = EdgeInsets.symmetric(
    horizontal: kScreenHorizontalPadding,
    vertical: 12,
  );

  /// Softer than the default theme divider (both Recents and search results).
  static const Color _listDividerColor = Color(0xFFEDEDF1);

  List<Widget> _recentListRows(
    BuildContext context, {
    required List<String> tags,
    required List<String> queries,
    required List<RecentSearchUser> users,
  }) {
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF6C6C74),
          fontWeight: FontWeight.w700,
        );
    final out = <Widget>[];

    void divider() => out.add(
          const Divider(height: 1, thickness: 1, color: _listDividerColor),
        );

    Widget sectionLabel(String text) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          kScreenHorizontalPadding,
          8,
          kScreenHorizontalPadding,
          4,
        ),
        child: Text(text, style: labelStyle),
      );
    }

    if (tags.isNotEmpty) {
      out.add(sectionLabel('Tags'));
      for (var i = 0; i < tags.length; i++) {
        if (i > 0) divider();
        final t = tags[i];
        out.add(
          _recentRow(
            leading: const Icon(Icons.tag, color: Color(0xFF6D6D75)),
            title: '#$t',
            onTap: () => _openTag(t),
            onRemove: () => _removeRecentTag(t),
          ),
        );
      }
      if (queries.isNotEmpty || users.isNotEmpty) divider();
    }
    if (queries.isNotEmpty) {
      out.add(sectionLabel('Searches'));
      for (var i = 0; i < queries.length; i++) {
        if (i > 0) divider();
        final q = queries[i];
        out.add(
          _recentRow(
            leading: const Icon(Icons.search, color: Color(0xFF6D6D75)),
            title: q,
            onTap: () => _applyRecentQuery(q),
            onRemove: () => _removeRecentQuery(q),
          ),
        );
      }
      if (users.isNotEmpty) divider();
    }
    if (users.isNotEmpty) {
      out.add(sectionLabel('Profiles'));
      for (var i = 0; i < users.length; i++) {
        if (i > 0) divider();
        final u = users[i];
        out.add(
          _recentRow(
            leading: ProfileAvatar(
              imageUrl: u.avatarUrl,
              radius: 22,
            ),
            title: u.username,
            onTap: () => _openUser(u),
            onRemove: () => _removeRecentUser(u.id),
          ),
        );
      }
    }
    return out;
  }

  Widget _recentRow({
    required Widget leading,
    required String title,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: _rowPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 20, color: Color(0xFF6D6D75)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsBody() {
    if (_loadingSearch) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchError != null) {
      return Center(child: Text(_searchError!, textAlign: TextAlign.center));
    }
    final tag = _normalizedTagQuery;
    if (_results.isEmpty && tag.isEmpty) {
      return const Center(
        child: Text(
          'No users found.',
          style: TextStyle(color: Color(0xFF6C6C74)),
        ),
      );
    }
    return ListView.separated(
      itemCount: _results.length + (tag.isNotEmpty ? 1 : 0),
      separatorBuilder: (_, __) =>
          const Divider(height: 1, thickness: 1, color: _listDividerColor),
      itemBuilder: (context, index) {
        if (tag.isNotEmpty && index == 0) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openTag(tag),
              child: Padding(
                padding: _rowPadding,
                child: Row(
                  children: [
                    const Icon(Icons.tag, color: Color(0xFF6D6D75)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'See posts tagged #$tag',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final offset = tag.isNotEmpty ? 1 : 0;
        final u = _results[index - offset];
        final name = u.username.isNotEmpty ? u.username : 'User';
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openUser(
              RecentSearchUser(id: u.id, username: name, avatarUrl: u.avatarUrl),
            ),
            child: Padding(
              padding: _rowPadding,
              child: Row(
                children: [
                  ProfileAvatar(
                    imageUrl: u.avatarUrl,
                    radius: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String get _normalizedTagQuery {
    final q = _controller.text.trim();
    if (q.isEmpty) return '';
    return q.replaceFirst(RegExp(r'^#'), '');
  }

  Future<void> _openTag(String tag) async {
    final q = tag.trim().replaceFirst(RegExp(r'^#'), '');
    if (q.isEmpty) return;
    final uid = await _api.getCurrentUserId();
    await RecentSearchesStorage.addTag(uid, q);
    if (!mounted) return;
    await _loadRecent();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TaggedPostsScreen(initialTag: q),
      ),
    );
  }
}

class _SearchHit {
  final int id;
  final String username;
  final String? avatarUrl;

  _SearchHit({required this.id, required this.username, this.avatarUrl});

  factory _SearchHit.fromJson(Map<String, dynamic> json) {
    var id = 0;
    final rawId = json['id'];
    if (rawId is int) {
      id = rawId;
    } else if (rawId is num) {
      id = rawId.toInt();
    } else if (rawId is String) {
      id = int.tryParse(rawId) ?? 0;
    }
    final rawAvatar = json['avatarUrl'] ?? json['avatar_url'];
    String? avatar;
    if (rawAvatar is String) {
      avatar = rawAvatar.trim().isEmpty ? null : rawAvatar.trim();
    }
    return _SearchHit(
      id: id,
      username: (json['username'] as String?)?.trim() ?? '',
      avatarUrl: avatar,
    );
  }
}
