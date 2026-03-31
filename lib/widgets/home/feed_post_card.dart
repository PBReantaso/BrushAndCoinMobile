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
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 6, 8),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFB1B1B1),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    author,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF242424),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert, size: 20),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1.05,
            child: _postImage(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Row(
              children: [
                InkWell(
                  onTap: onLikeTap,
                  child: Icon(
                    likedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: const Color(0xFFFF4A4A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 4),
                Text('$likeCount', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 14),
                InkWell(
                  onTap: onCommentTap,
                  child: const Icon(Icons.comment, color: Color(0xFFFF4A4A), size: 18),
                ),
                const SizedBox(width: 4),
                Text('$commentCount', style: const TextStyle(fontSize: 12)),
                const Spacer(),
                const Icon(Icons.share, color: Color(0xFFFF4A4A), size: 18),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF303030),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A4A4A),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF595959),
              ),
            ),
          ),
          if (tags.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Text(
                'Tags',
                style: TextStyle(fontSize: 12, color: Color(0xFF353535)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
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
                        color: const Color(0xFFD1D1D1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1F1F1F),
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

