import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../search/tagged_posts_screen.dart';
import '../../theme/content_spacing.dart';
import '../../widgets/common/bc_app_bar.dart';
import '../../widgets/home/edit_post_bottom_sheet.dart';
import '../../widgets/home/feed_post_card.dart';
import '../../widgets/home/post_comments_sheet.dart';

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
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _refreshFeed();
  }

  Future<void> _loadCurrentUserId() async {
    final id = await _apiClient.getCurrentUserId();
    if (mounted) setState(() => _currentUserId = id);
  }

  Future<void> _refreshFeed({bool showFullScreenLoading = true}) async {
    if (showFullScreenLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = null);
    }
    try {
      final postsRaw = await _apiClient.fetchFeedPosts();
      if (!mounted) return;
      setState(() {
        _posts = postsRaw.map(_FeedPost.fromJson).toList();
        _errorMessage = null;
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
      if (mounted && showFullScreenLoading) {
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
              ? RefreshIndicator(
                  color: const Color(0xFFFF4A4A),
                  onRefresh: () => _refreshFeed(showFullScreenLoading: false),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(
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
                                  onPressed: () => _refreshFeed(showFullScreenLoading: true),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFFF4A4A),
                  onRefresh: () => _refreshFeed(showFullScreenLoading: false),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(
                        child: Divider(height: 1, color: Color(0xFFD8D8DE)),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: kContentBelowAppBarPadding),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kScreenHorizontalPadding,
                        ),
                        sliver: SliverList.separated(
                        itemCount: _posts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final p = _posts[index];
                          final isOwner =
                              _currentUserId != null && _currentUserId == p.userId;
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
                            onLikeTap: () => _toggleLike(p),
                            onCommentTap: () => _commentOnPost(p),
                            onTagTap: (tag) => _openTag(tag),
                            isOwner: isOwner,
                            onEditPost: isOwner ? () => _editPost(p) : null,
                            isEdited: p.isEditedPost,
                          );
                        },
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return PostCommentsSheet(
          postId: post.id,
          apiClient: _apiClient,
          onCommentAdded: () {
            _updatePost(
              post.id,
              (current) => current.copyWith(commentCount: current.commentCount + 1),
            );
          },
        );
      },
    );
  }

  void _updatePost(int postId, _FeedPost Function(_FeedPost current) mapper) {
    if (!mounted) return;
    setState(() {
      _posts = _posts
          .map((p) => p.id == postId ? mapper(p) : p)
          .toList(growable: false);
    });
  }

  Future<void> _editPost(_FeedPost post) async {
    final result = await showEditPostBottomSheet(
      context,
      initialTitle: post.title,
      initialDescription: post.description,
    );
    if (result == null || !mounted) return;
    try {
      final updated = await _apiClient.updatePost(
        postId: post.id,
        title: result.title,
        description: result.description,
      );
      if (!mounted) return;
      final merged = _FeedPost.fromJson(updated);
      _updatePost(post.id, (_) => merged);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
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

class _FeedPost {
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
  /// ISO timestamp from API when the post was last edited; null if never edited.
  final String? editedAt;

  const _FeedPost({
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
    this.editedAt,
  });

  bool get isEditedPost {
    final e = editedAt?.trim() ?? '';
    return e.isNotEmpty;
  }

  factory _FeedPost.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = rawTags is List ? rawTags.map((e) => '$e').toList() : const <String>[];
    final av = json['authorAvatarUrl'];
    final rawEdited = json['editedAt'];
    final editedAt =
        rawEdited is String && rawEdited.trim().isNotEmpty ? rawEdited.trim() : null;
    return _FeedPost(
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
      editedAt: editedAt,
    );
  }

  _FeedPost copyWith({
    String? authorName,
    String? authorAvatarUrl,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    String? imageUrl,
    String? createdAtText,
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
    String? editedAt,
  }) {
    return _FeedPost(
      id: id,
      userId: userId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAtText: createdAtText ?? this.createdAtText,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
      editedAt: editedAt ?? this.editedAt,
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
