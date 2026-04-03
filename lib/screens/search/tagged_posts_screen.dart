import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../widgets/home/feed_post_card.dart';

class TaggedPostsScreen extends StatefulWidget {
  final String initialTag;

  const TaggedPostsScreen({super.key, required this.initialTag});

  @override
  State<TaggedPostsScreen> createState() => _TaggedPostsScreenState();
}

class _TaggedPostsScreenState extends State<TaggedPostsScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<_TaggedPost> _posts = const [];

  String get _tag => widget.initialTag.trim().replaceFirst(RegExp(r'^#'), '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _api.fetchTaggedPosts(_tag);
      if (!mounted) return;
      setState(() {
        _posts = raw.map(_TaggedPost.fromJson).toList();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDF1),
        elevation: 0,
        title: Text('#$_tag', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : _posts.isEmpty
                  ? Center(
                      child: Text(
                        'No posts tagged #$_tag yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6C6C74),
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final p = _posts[index];
                        return FeedPostCard(
                          postId: p.id,
                          authorUserId: p.userId,
                          author: p.authorName.isEmpty ? 'Brush&Coin' : p.authorName,
                          authorAvatarUrl: p.authorAvatarUrl,
                          subtitle: p.createdAtText,
                          category: p.category,
                          title: p.title.isEmpty ? 'Untitled Post' : p.title,
                          description: p.description,
                          tags: p.tags,
                          imageUrl: p.imageUrl,
                          likeCount: p.likeCount,
                          commentCount: p.commentCount,
                          likedByMe: p.likedByMe,
                          onLikeTap: () {},
                          onCommentTap: () {},
                          onTagTap: (nextTag) {
                            if (nextTag == _tag) return;
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TaggedPostsScreen(initialTag: nextTag),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}

class _TaggedPost {
  final int id;
  final int userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final String? imageUrl;
  final String createdAtText;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  const _TaggedPost({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.imageUrl,
    required this.createdAtText,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
  });

  factory _TaggedPost.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = rawTags is List ? rawTags.map((e) => '$e').toList() : const <String>[];
    final av = json['authorAvatarUrl'];
    return _TaggedPost(
      id: _readInt(json['id']),
      userId: _readInt(json['userId']),
      authorName: (json['authorName'] as String?) ?? '',
      authorAvatarUrl: av is String && av.trim().isNotEmpty ? av.trim() : null,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?)?.trim() ?? '',
      tags: tags,
      imageUrl: json['imageUrl'] as String?,
      createdAtText: _formatCreatedAt((json['createdAt'] as String?) ?? ''),
      likeCount: _readInt(json['likeCount']),
      commentCount: _readInt(json['commentCount']),
      likedByMe: (json['likedByMe'] as bool?) ?? false,
    );
  }
}

String _formatCreatedAt(String raw) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) return '';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
