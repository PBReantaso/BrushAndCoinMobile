import 'package:flutter/material.dart';

import '../../navigation/user_profile_navigation.dart';
import '../../theme/content_spacing.dart';
import '../../services/api_client.dart';
import '../../state/app_profile_scope.dart';
import '../profile/profile_avatar.dart';

const Color _kCommentFieldBorder = Color(0xFFE0E0E8);
const Color _kBrandRed = Color(0xFFFF4A4A);

/// Bottom sheet for post comments (shared by home feed and profile post viewer).
class PostCommentsSheet extends StatefulWidget {
  final int postId;
  final ApiClient apiClient;
  final VoidCallback onCommentAdded;

  const PostCommentsSheet({
    super.key,
    required this.postId,
    required this.apiClient,
    required this.onCommentAdded,
  });

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _loading = true;
  bool _posting = false;
  String? _error;
  List<PostComment> _comments = const [];
  /// From `/auth/me` so the composer shows the same avatar as the server profile.
  String? _meAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadMyAvatarForComposer();
    _loadComments();
  }

  Future<void> _loadMyAvatarForComposer() async {
    try {
      final j = await widget.apiClient.fetchMe();
      final user = j['user'];
      if (user is Map) {
        final av = user['avatarUrl'];
        if (av is String && av.trim().isNotEmpty && mounted) {
          setState(() => _meAvatarUrl = av.trim());
        }
      }
    } catch (_) {
      // Keep AppProfileScope / placeholder fallback
    }
  }

  @override
  void dispose() {
    _commentFocus.dispose();
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
        _comments = data.map(PostComment.fromJson).toList();
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
                              padding: const EdgeInsets.fromLTRB(
                                kScreenHorizontalPadding,
                                12,
                                kScreenHorizontalPadding,
                                16,
                              ),
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
              padding: EdgeInsets.fromLTRB(
                kScreenHorizontalPadding,
                10,
                kScreenHorizontalPadding,
                kb > 0 ? kb + 8 : 10,
              ),
              child: Row(
                children: [
                  ListenableBuilder(
                    listenable: AppProfileScope.of(context),
                    builder: (context, _) {
                      final scopeUrl = AppProfileScope.of(context).profile.avatarUrl;
                      final url = _meAvatarUrl ?? scopeUrl;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ProfileAvatar(imageUrl: url, radius: 18),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocus,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Join the conversation...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: _kCommentFieldBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: _kCommentFieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: _kBrandRed, width: 2),
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

class PostComment {
  final int userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String comment;
  final DateTime? createdAt;

  const PostComment({
    required this.userId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.comment,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final av = json['authorAvatarUrl'];
    return PostComment(
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

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
