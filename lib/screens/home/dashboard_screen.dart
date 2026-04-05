import 'package:flutter/material.dart';

import '../../navigation/user_profile_navigation.dart';
import '../../services/api_client.dart';
import '../search/tagged_posts_screen.dart';
import '../../theme/content_spacing.dart';
import '../../state/app_profile_scope.dart';
import '../../widgets/common/bc_app_bar.dart';
import '../../widgets/home/edit_post_bottom_sheet.dart';
import '../../widgets/home/feed_post_card.dart';
import '../../widgets/profile/profile_avatar.dart';

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
                      SliverList.separated(
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
                          );
                        },
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
        return _CommentsSheet(
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

class _CommentsSheet extends StatefulWidget {
  final int postId;
  final ApiClient apiClient;
  final VoidCallback onCommentAdded;

  const _CommentsSheet({
    required this.postId,
    required this.apiClient,
    required this.onCommentAdded,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _loading = true;
  bool _posting = false;
  String? _error;
  List<_PostComment> _comments = const [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.apiClient.fetchPostComments(widget.postId);
      if (!mounted) return;
      setState(() {
        _comments = data.map(_PostComment.fromJson).toList();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      await widget.apiClient.commentOnPost(postId: widget.postId, comment: text);
      _commentController.clear();
      widget.onCommentAdded();
      await _loadComments();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC8C8CF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Comments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _comments.isEmpty
                          ? const Center(child: Text('No comments yet. Start the conversation.'))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                              itemCount: _comments.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final c = _comments[index];
                                return InkWell(
                                  onTap: c.userId > 0
                                      ? () {
                                          pushUserProfile(
                                            context,
                                            userId: c.userId,
                                            username: c.authorName,
                                          );
                                        }
                                      : null,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ProfileAvatar(
                                        imageUrl: c.authorAvatarUrl,
                                        radius: 16,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  c.authorName,
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                        color: const Color(0xFF1A1A1E),
                                                      ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  c.timeAgo,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: const Color(0xFF7A7A82),
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              c.comment,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: const Color(0xFF2F2F36),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, kb > 0 ? kb + 8 : 10),
              child: Row(
                children: [
                  ListenableBuilder(
                    listenable: AppProfileScope.of(context),
                    builder: (context, _) {
                      final url = AppProfileScope.of(context).profile.avatarUrl;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ProfileAvatar(imageUrl: url, radius: 18),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Join the conversation...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E8)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _posting ? null : _submitComment,
                    icon: _posting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostComment {
  final int userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String comment;
  final DateTime? createdAt;

  const _PostComment({
    required this.userId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.comment,
    required this.createdAt,
  });

  factory _PostComment.fromJson(Map<String, dynamic> json) {
    final av = json['authorAvatarUrl'];
    return _PostComment(
      userId: _readInt(json['userId']),
      authorName: (json['authorName'] as String?) ?? 'User',
      authorAvatarUrl: av is String && av.trim().isNotEmpty ? av.trim() : null,
      comment: (json['comment'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
    );
  }

  String get timeAgo {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(createdAt!);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
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
  });

  factory _FeedPost.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = rawTags is List ? rawTags.map((e) => '$e').toList() : const <String>[];
    final av = json['authorAvatarUrl'];
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
