import 'dart:async';

import 'package:flutter/material.dart';

import '../../navigation/user_profile_navigation.dart';
import '../../services/api_client.dart';
import '../../services/recent_searches_storage.dart';
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
  List<RecentSearchUser> _recent = [];
  List<_SearchHit> _results = [];
  bool _loadingRecent = true;
  bool _loadingSearch = false;
  String? _searchError;

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
    final list = await RecentSearchesStorage.load();
    if (!mounted) return;
    setState(() {
      _recent = list;
      _loadingRecent = false;
    });
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
    RecentSearchesStorage.add(RecentSearchUser(id: user.id, username: hint)).then((_) {
      if (mounted) _loadRecent();
    });
  }

  Future<void> _removeRecent(int id) async {
    await RecentSearchesStorage.remove(id);
    await _loadRecent();
  }

  Future<void> _clearRecent() async {
    await RecentSearchesStorage.clear();
    await _loadRecent();
  }

  @override
  Widget build(BuildContext context) {
    final showRecent = _controller.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDF1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
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
      ),
      body: showRecent
          ? _buildRecentBody()
          : _buildResultsBody(),
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
          child: ListView.separated(
            itemCount: _recent.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final u = _recent[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openUser(u),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFD8D8DE),
                          child: Icon(Icons.person, color: Color(0xFF6D6D75)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            u.username,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => _removeRecent(u.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (tag.isNotEmpty && index == 0) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openTag(tag),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openUser(RecentSearchUser(id: u.id, username: u.username)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFD8D8DE),
                    child: Icon(Icons.person, color: Color(0xFF6D6D75)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      u.username.isNotEmpty ? u.username : 'User',
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

  void _openTag(String tag) {
    final q = tag.trim().replaceFirst(RegExp(r'^#'), '');
    if (q.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaggedPostsScreen(initialTag: q),
      ),
    );
  }
}

class _SearchHit {
  final int id;
  final String username;

  _SearchHit({required this.id, required this.username});

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
    return _SearchHit(
      id: id,
      username: (json['username'] as String?)?.trim() ?? '',
    );
  }
}
