import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/content_spacing.dart';
import '../search/tagged_posts_screen.dart';
import '../../widgets/common/report_reason_dialog.dart';
import '../../widgets/home/edit_post_bottom_sheet.dart';
import '../../widgets/home/feed_post_card.dart';
import '../../widgets/home/post_comments_sheet.dart';

/// Full-height scroll through profile posts (same cards and spacing as home feed).
class ProfilePostViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final int initialIndex;
  final int? currentUserId;

  const ProfilePostViewerScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
    this.currentUserId,
  });

  @override
  State<ProfilePostViewerScreen> createState() => _ProfilePostViewerScreenState();
}

class _ProfilePostViewerScreenState extends State<ProfilePostViewerScreen> {
  final _api = ApiClient();
  final _scrollController = ScrollController();
  late final List<GlobalKey> _itemKeys;
  late List<Map<String, dynamic>> _posts;

  @override
  void initState() {
    super.initState();
    _posts = widget.posts.map((m) => Map<String, dynamic>.from(m)).toList();
    final n = _posts.length;
    _itemKeys = List.generate(n, (_) => GlobalKey());
    if (n > 0) {
      final safeIndex = widget.initialIndex.clamp(0, n - 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToIndex(safeIndex);
      });
    }
  }

  void _scrollToIndex(int index) {
    if (!mounted || index < 0 || index >= _itemKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _itemKeys[index].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0,
          duration: Duration.zero,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _mergePost(int postId, Map<String, dynamic> updated) {
    setState(() {
      _posts = _posts
          .map((p) => _readInt(p['id']) == postId ? Map<String, dynamic>.from(updated) : p)
          .toList(growable: false);
    });
  }

  void _bumpCommentCount(int postId) {
    setState(() {
      _posts = _posts.map((p) {
        if (_readInt(p['id']) != postId) return p;
        final next = Map<String, dynamic>.from(p);
        next['commentCount'] = _readInt(p['commentCount']) + 1;
        return next;
      }).toList(growable: false);
    });
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final postId = _readInt(post['id']);
    final wasLiked = (post['likedByMe'] as bool?) ?? false;
    final delta = wasLiked ? -1 : 1;
    setState(() {
      final i = _posts.indexWhere((p) => _readInt(p['id']) == postId);
      if (i < 0) return;
      final next = Map<String, dynamic>.from(_posts[i]);
      next['likedByMe'] = !wasLiked;
      next['likeCount'] = (_readInt(next['likeCount']) + delta).clamp(0, 1 << 30);
      _posts[i] = next;
    });
    try {
      if (wasLiked) {
        await _api.unlikePost(postId);
      } else {
        await _api.likePost(postId);
      }
    } on ApiException catch (e) {
      setState(() {
        final i = _posts.indexWhere((p) => _readInt(p['id']) == postId);
        if (i < 0) return;
        final next = Map<String, dynamic>.from(_posts[i]);
        next['likedByMe'] = wasLiked;
        next['likeCount'] = (_readInt(next['likeCount']) - delta).clamp(0, 1 << 30);
        _posts[i] = next;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _commentOnPost(Map<String, dynamic> post) async {
    final postId = _readInt(post['id']);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return PostCommentsSheet(
          postId: postId,
          apiClient: _api,
          onCommentAdded: () => _bumpCommentCount(postId),
        );
      },
    );
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

  Future<void> _editPost(Map<String, dynamic> post) async {
    final title = (post['title'] as String?) ?? '';
    final description = (post['description'] as String?) ?? '';
    final result = await showEditPostBottomSheet(
      context,
      initialTitle: title,
      initialDescription: description,
    );
    if (result == null || !mounted) return;
    final postId = _readInt(post['id']);
    try {
      final updated = await _api.updatePost(
        postId: postId,
        title: result.title,
        description: result.description,
      );
      if (!mounted) return;
      _mergePost(postId, updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _reportPost(Map<String, dynamic> post) async {
    final reason = await showReportReasonDialog(
      context,
      title: 'Report this post?',
    );
    if (!mounted || reason == null) return;
    final postId = _readInt(post['id']);
    try {
      final json = await _api.reportPost(postId: postId, reason: reason);
      if (!mounted) return;
      final dup = json['alreadyReported'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dup ? 'You already reported this post.' : 'Thanks — we\'ll review your report.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final postId = _readInt(post['id']);
    try {
      await _api.deletePost(postId);
      if (!mounted) return;
      setState(() {
        _posts = _posts.where((p) => _readInt(p['id']) != postId).toList();
        _itemKeys = List.generate(_posts.length, (_) => GlobalKey());
      });
      if (_posts.isEmpty && mounted) {
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _buildCard(Map<String, dynamic> json) {
    final postId = _readInt(json['id']);
    final userId = _readInt(json['userId']);
    final authorName = (json['authorName'] as String?) ?? '';
    final av = json['authorAvatarUrl'];
    final authorAvatarUrl = av is String && av.trim().isNotEmpty ? av.trim() : null;
    final titleRaw = (json['title'] as String?) ?? '';
    final description = (json['description'] as String?) ?? '';
    final category = (json['category'] as String?)?.trim() ?? '';
    final rawTags = json['tags'];
    final tags = rawTags is List ? rawTags.map((e) => '$e').toList() : const <String>[];
    final imageUrl = json['imageUrl'] as String?;
    final createdAtText = _formatCreatedAt((json['createdAt'] as String?) ?? '');
    final likeCount = _readInt(json['likeCount']);
    final commentCount = _readInt(json['commentCount']);
    final likedByMe = (json['likedByMe'] as bool?) ?? false;
    final rawEdited = json['editedAt'];
    final isEdited = rawEdited is String && rawEdited.trim().isNotEmpty;

    final uid = widget.currentUserId;
    final isOwner = uid != null && uid == userId;

    return FeedPostCard(
      postId: postId,
      authorUserId: userId,
      author: authorName.isEmpty ? 'Brush&Coin' : authorName,
      authorAvatarUrl: authorAvatarUrl,
      subtitle: createdAtText,
      category: category,
      title: titleRaw.isEmpty ? 'Untitled Post' : titleRaw,
      description: description,
      tags: tags,
      imageUrl: imageUrl,
      likeCount: likeCount,
      commentCount: commentCount,
      likedByMe: likedByMe,
      onLikeTap: () => _toggleLike(json),
      onCommentTap: () => _commentOnPost(json),
      onTagTap: _openTag,
      isOwner: isOwner,
      onEditPost: isOwner ? () => _editPost(json) : null,
      onDeletePost: isOwner ? () => _deletePost(json) : null,
      onReportPost: (!isOwner && uid != null) ? () => _reportPost(json) : null,
      isEdited: isEdited,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BcColors.pageBackground,
      appBar: AppBar(
        leading: const BackButton(color: BcColors.ink),
        title: Text('Posts', style: bcPushedScreenTitleStyle(context)),
        backgroundColor: Colors.white,
        foregroundColor: BcColors.ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        bottom: const BcAppBarBottomLine(),
      ),
      body: _posts.isEmpty
          ? const Center(child: Text('No posts'))
          : ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                kScreenHorizontalPadding,
                0,
                kScreenHorizontalPadding,
                24,
              ),
              children: [
                for (int i = 0; i < _posts.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  KeyedSubtree(
                    key: _itemKeys[i],
                    child: _buildCard(_posts[i]),
                  ),
                ],
              ],
            ),
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
