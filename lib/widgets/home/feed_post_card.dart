import 'package:flutter/material.dart';

import '../../navigation/user_profile_navigation.dart';
import '../profile/profile_avatar.dart';
import 'post_image_display.dart';

class FeedPostCard extends StatelessWidget {
  final int postId;
  final int authorUserId;
  final String author;
  /// Author profile photo URL (or data URI); from API `authorAvatarUrl`.
  final String? authorAvatarUrl;
  /// Shown under the username when [category] is empty (typically post date).
  final String subtitle;
  /// e.g. "Digital Art"; when non-empty, shown under the username instead of [subtitle].
  final String category;
  final String title;
  final String description;
  final List<String> tags;
  final String? imageUrl;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final ValueChanged<String>? onTagTap;
  /// When true and [onEditPost] / [onDeletePost] are set, the header menu includes those actions.
  final bool isOwner;
  final VoidCallback? onEditPost;
  final VoidCallback? onDeletePost;
  /// Shown for other users' posts (not your own); overflow "Report".
  final VoidCallback? onReportPost;
  /// Shown when the post was saved after an edit (API `editedAt`).
  final bool isEdited;
  /// When false, hides like/comment/bookmark row (e.g. merchandise-only view).
  final bool showEngagement;
  /// Description line clamp; use a large value (e.g. 50) for long text.
  final int descriptionMaxLines;

  const FeedPostCard({
    super.key,
    required this.postId,
    required this.authorUserId,
    required this.author,
    this.authorAvatarUrl,
    required this.subtitle,
    this.category = '',
    required this.title,
    required this.description,
    required this.tags,
    required this.imageUrl,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.onLikeTap,
    required this.onCommentTap,
    this.onTagTap,
    this.isOwner = false,
    this.onEditPost,
    this.onDeletePost,
    this.onReportPost,
    this.isEdited = false,
    this.showEngagement = true,
    this.descriptionMaxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final categoryTrim = category.trim();
    final String? headerSecondLine;
    if (categoryTrim.isNotEmpty) {
      headerSecondLine = categoryTrim;
    } else if (subtitle.isEmpty) {
      headerSecondLine = isEdited ? 'Edited' : null;
    } else {
      headerSecondLine = isEdited ? '$subtitle · Edited' : subtitle;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 6, 8),
            child: Row(
              children: [
                _authorTap(
                  context,
                  child: ProfileAvatar(
                    imageUrl: authorAvatarUrl,
                    radius: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _authorTap(
                        context,
                        child: Text(
                          author,
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF171717),
                          ),
                        ),
                      ),
                      if (headerSecondLine != null && headerSecondLine.isNotEmpty)
                        Text(
                          headerSecondLine,
                          style: t.labelSmall?.copyWith(
                            color: const Color(0xFF6C6C72),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isOwner && (onEditPost != null || onDeletePost != null))
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_horiz, size: 20, color: Color(0xFF3A3A3F)),
                    onSelected: (value) {
                      if (value == 'edit') onEditPost?.call();
                      if (value == 'delete') onDeletePost?.call();
                    },
                    itemBuilder: (context) => [
                      if (onEditPost != null)
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit post'),
                        ),
                      if (onDeletePost != null)
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete post', style: TextStyle(color: Color(0xFFC62828))),
                        ),
                    ],
                  )
                else if (!isOwner && onReportPost != null)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_horiz, size: 20, color: Color(0xFF3A3A3F)),
                    onSelected: (value) {
                      if (value == 'report') onReportPost?.call();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'report',
                        child: Text('Report'),
                      ),
                    ],
                  )
                else
                  const SizedBox(width: 40, height: 40),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: PostImageDisplay(imageUrl: imageUrl, fit: BoxFit.cover),
            ),
          ),
          if (showEngagement)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                children: [
                  InkWell(
                    onTap: onLikeTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        likedByMe ? Icons.favorite : Icons.favorite_border,
                        color: likedByMe
                            ? const Color(0xFFFF4A4A)
                            : const Color(0xFF202025),
                        size: 23,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$likeCount',
                    style: t.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(width: 14),
                  InkWell(
                    onTap: onCommentTap,
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(Icons.mode_comment_outlined, color: Color(0xFF202025), size: 22),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$commentCount',
                    style: t.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.bookmark_border, color: Color(0xFF202025), size: 23),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 0,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: authorUserId > 0
                      ? () => pushUserProfile(context, userId: authorUserId, username: author)
                      : null,
                  child: Text(
                    author,
                    style: t.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1D),
                    ),
                  ),
                ),
                if (title.isNotEmpty)
                  Text(
                    ' $title',
                    style: t.bodyMedium?.copyWith(color: const Color(0xFF1B1B1D)),
                  ),
              ],
            ),
          ),
          if (description.isNotEmpty || subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: Text(
                description,
                maxLines: descriptionMaxLines > 0 ? descriptionMaxLines : null,
                overflow: descriptionMaxLines > 0 ? TextOverflow.ellipsis : TextOverflow.visible,
                style: t.bodyMedium?.copyWith(color: const Color(0xFF3F3F45)),
              ),
            ),
          if (categoryTrim.isNotEmpty && (subtitle.isNotEmpty || isEdited))
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Text(
                subtitle.isEmpty
                    ? 'Edited'
                    : (isEdited ? '$subtitle · Edited' : subtitle),
                style: t.bodySmall?.copyWith(
                  color: const Color(0xFF8A8A90),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          if (tags.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Text(
                'Tags',
                style: t.bodySmall?.copyWith(color: const Color(0xFF353535)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in tags)
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onTagTap == null ? null : () => onTagTap!(_normalizeTag(tag)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F4),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFE0E0E6)),
                        ),
                        child: Text(
                          '#${_normalizeTag(tag)}',
                          style: t.labelSmall?.copyWith(color: const Color(0xFF2B2B31)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _authorTap(BuildContext context, {required Widget child}) {
    if (authorUserId <= 0) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => pushUserProfile(context, userId: authorUserId, username: author),
      child: child,
    );
  }

}

String _normalizeTag(String raw) {
  return raw.trim().replaceFirst(RegExp(r'^#'), '');
}
