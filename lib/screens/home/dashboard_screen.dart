import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../widgets/common/bc_app_bar.dart';
import '../../widgets/home/feed_post_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  String? _errorMessage;
  List<_FeedPost> _posts = const [];

  @override
  void initState() {
    super.initState();
    _refreshFeed();
  }

  Future<void> _refreshFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final postsRaw = await _apiClient.fetchFeedPosts();
      if (!mounted) return;
      setState(() {
        _posts = postsRaw.map(_FeedPost.fromJson).toList();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BcAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Failed to load home feed.'),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _refreshFeed,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Divider(height: 1, color: Color(0xFFD8D8DE)),
              ),
              SliverList.separated(
                itemCount: _posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = _posts[index];
                  return FeedPostCard(
                    postId: p.id,
                    author: p.authorName.isEmpty ? 'Brush&Coin' : p.authorName,
                    subtitle: p.createdAtText,
                    title: p.title.isEmpty ? 'Untitled Post' : p.title,
                    description: p.description,
                    tags: p.tags,
                    imageUrl: p.imageUrl,
                    likeCount: p.likeCount,
                    commentCount: p.commentCount,
                    likedByMe: p.likedByMe,
                    onLikeTap: () => _toggleLike(p),
                    onCommentTap: () => _commentOnPost(p),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
    );
  }

  Future<void> _toggleLike(_FeedPost post) async {
    final wasLiked = post.likedByMe;
    final delta = wasLiked ? -1 : 1;
    _updatePost(
      post.id,
      (current) => current.copyWith(
        likedByMe: !wasLiked,
        likeCount: (current.likeCount + delta).clamp(0, 1 << 30),
      ),
    );
    try {
      if (wasLiked) {
        await _apiClient.unlikePost(post.id);
      } else {
        await _apiClient.likePost(post.id);
      }
    } on ApiException catch (e) {
      _updatePost(
        post.id,
        (current) => current.copyWith(
          likedByMe: wasLiked,
          likeCount: (current.likeCount - delta).clamp(0, 1 << 30),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _commentOnPost(_FeedPost post) async {
    final controller = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add comment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Write your comment'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (comment == null || comment.isEmpty) return;
    _updatePost(
      post.id,
      (current) => current.copyWith(commentCount: current.commentCount + 1),
    );
    try {
      await _apiClient.commentOnPost(postId: post.id, comment: comment);
    } on ApiException catch (e) {
      _updatePost(
        post.id,
        (current) =>
            current.copyWith(commentCount: (current.commentCount - 1).clamp(0, 1 << 30)),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _updatePost(int postId, _FeedPost Function(_FeedPost current) mapper) {
    if (!mounted) return;
    setState(() {
      _posts = _posts
          .map((p) => p.id == postId ? mapper(p) : p)
          .toList(growable: false);
    });
  }
}

class _FeedPost {
  final int id;
  final String authorName;
  final String title;
  final String description;
  final List<String> tags;
  final String? imageUrl;
  final String createdAtText;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  const _FeedPost({
    required this.id,
    required this.authorName,
    required this.title,
    required this.description,
    required this.tags,
    required this.imageUrl,
    required this.createdAtText,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
  });

  factory _FeedPost.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = rawTags is List ? rawTags.map((e) => '$e').toList() : const <String>[];
    return _FeedPost(
      id: _readInt(json['id']),
      authorName: (json['authorName'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      tags: tags,
      imageUrl: json['imageUrl'] as String?,
      createdAtText: _formatCreatedAt((json['createdAt'] as String?) ?? ''),
      likeCount: _readInt(json['likeCount']),
      commentCount: _readInt(json['commentCount']),
      likedByMe: (json['likedByMe'] as bool?) ?? false,
    );
  }

  _FeedPost copyWith({
    String? authorName,
    String? title,
    String? description,
    List<String>? tags,
    String? imageUrl,
    String? createdAtText,
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
  }) {
    return _FeedPost(
      id: id,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAtText: createdAtText ?? this.createdAtText,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
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
