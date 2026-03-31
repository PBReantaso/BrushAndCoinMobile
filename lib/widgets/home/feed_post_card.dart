import 'dart:io';

import 'package:flutter/material.dart';

class FeedPostCard extends StatelessWidget {
  final int postId;
  final String author;
  final String subtitle;
  final String title;
  final String description;
  final List<String> tags;
  final String? imageUrl;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;

  const FeedPostCard({
    super.key,
    required this.postId,
    required this.author,
    required this.subtitle,
    required this.title,
    required this.description,
    required this.tags,
    required this.imageUrl,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.onLikeTap,
    required this.onCommentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF4A4A), width: 1.2),
                  ),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFD2D2D7),
                    child: Icon(Icons.person, color: Color(0xFF77777E), size: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171717),
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6C6C72),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.more_horiz, size: 20, color: Color(0xFF3A3A3F)),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: _postImage(),
            ),
          ),
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
                      color: const Color(0xFF202025),
                      size: 23,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '$likeCount',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF111111)),
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
                  style: const TextStyle(fontSize: 16, color: Color(0xFF111111)),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.repeat_rounded, color: Color(0xFF202025), size: 22),
                const SizedBox(width: 3),
                const Text('0', style: TextStyle(fontSize: 16, color: Color(0xFF111111))),
                const Spacer(),
                const Icon(Icons.bookmark_border, color: Color(0xFF202025), size: 23),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF1B1B1D)),
                children: [
                  TextSpan(
                    text: author,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: title.isNotEmpty ? ' $title' : ''),
                ],
              ),
            ),
          ),
          if (description.isNotEmpty || subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF3F3F45)),
              ),
            ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A90)),
              ),
            ),
          if (tags.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Text(
                'Tags',
                style: TextStyle(fontSize: 12, color: Color(0xFF353535)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in tags)
                    Container(
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
                        t,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2B2B31),
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

  Widget _postImage() {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return _placeholder();
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder()),
        ),
      );
    }

    final file = File(url);
    if (!file.existsSync()) return _placeholder();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(file, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder()),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD8CAD9),
            Color(0xFFC7C7D9),
            Color(0xFFE2E2EA),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 38, color: Colors.black45),
      ),
    );
  }
}

