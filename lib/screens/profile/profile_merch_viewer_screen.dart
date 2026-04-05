import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/content_spacing.dart';
import '../../widgets/home/feed_post_card.dart';

/// Same layout as [ProfilePostViewerScreen] (feed-style cards) for merchandise items.
class ProfileMerchViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int initialIndex;
  final String authorName;
  final String? authorAvatarUrl;
  final int authorUserId;

  const ProfileMerchViewerScreen({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.authorName,
    this.authorAvatarUrl,
    required this.authorUserId,
  });

  @override
  State<ProfileMerchViewerScreen> createState() => _ProfileMerchViewerScreenState();
}

class _ProfileMerchViewerScreenState extends State<ProfileMerchViewerScreen> {
  late final List<GlobalKey> _itemKeys;
  late List<Map<String, dynamic>> _cards;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cards = widget.items.map(_merchAsPost).toList();
    final n = _cards.length;
    _itemKeys = List.generate(n, (_) => GlobalKey());
    if (n > 0) {
      final safeIndex = widget.initialIndex.clamp(0, n - 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToIndex(safeIndex);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Map<String, dynamic> _merchAsPost(Map<String, dynamic> m) {
    final mid = m['id'];
    final id = mid is int ? mid : (mid is num ? mid.toInt() : int.tryParse('$mid') ?? 0);
    final uidRaw = m['userId'];
    final uid = uidRaw is int
        ? uidRaw
        : (uidRaw is num ? uidRaw.toInt() : int.tryParse('$uidRaw') ?? 0);
    return {
      'id': id,
      'userId': uid > 0 ? uid : widget.authorUserId,
      'authorName': widget.authorName,
      'authorAvatarUrl': widget.authorAvatarUrl,
      'title': (m['title'] as String?)?.trim() ?? '',
      'description': (m['description'] as String?)?.trim() ?? '',
      'category': 'Merchandise',
      'tags': <String>[],
      'imageUrl': m['imageUrl'],
      'createdAt': m['createdAt'] ?? '',
      'likeCount': 0,
      'commentCount': 0,
      'likedByMe': false,
      'editedAt': null,
    };
  }

  String _formatCreatedAt(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return Scaffold(
        backgroundColor: BcColors.pageBackground,
        appBar: AppBar(
          leading: const BackButton(color: BcColors.ink),
          title: Text('Merchandise', style: bcPushedScreenTitleStyle(context)),
          backgroundColor: Colors.white,
          foregroundColor: BcColors.ink,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          bottom: const BcAppBarBottomLine(),
        ),
        body: const Center(child: Text('No merchandise')),
      );
    }

    return Scaffold(
      backgroundColor: BcColors.pageBackground,
      appBar: AppBar(
        leading: const BackButton(color: BcColors.ink),
        title: Text('Merchandise', style: bcPushedScreenTitleStyle(context)),
        backgroundColor: Colors.white,
        foregroundColor: BcColors.ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        bottom: const BcAppBarBottomLine(),
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          kScreenHorizontalPadding,
          0,
          kScreenHorizontalPadding,
          24,
        ),
        children: [
          for (int i = 0; i < _cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            KeyedSubtree(
              key: _itemKeys[i],
              child: _buildCard(_cards[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> json) {
    final userId = _readInt(json['userId']);
    final authorName = (json['authorName'] as String?) ?? '';
    final av = json['authorAvatarUrl'];
    final authorAvatarUrl = av is String && av.trim().isNotEmpty ? av.trim() : null;
    final titleRaw = (json['title'] as String?) ?? '';
    final description = (json['description'] as String?) ?? '';
    final imageUrl = json['imageUrl'] as String?;
    final createdAtText = _formatCreatedAt((json['createdAt'] as String?) ?? '');

    return FeedPostCard(
      postId: _readInt(json['id']),
      authorUserId: userId,
      author: authorName.isEmpty ? 'Brush&Coin' : authorName,
      authorAvatarUrl: authorAvatarUrl,
      subtitle: createdAtText,
      category: 'Merchandise',
      title: titleRaw.isEmpty ? 'Untitled' : titleRaw,
      description: description,
      tags: const [],
      imageUrl: imageUrl,
      likeCount: 0,
      commentCount: 0,
      likedByMe: false,
      onLikeTap: () {},
      onCommentTap: () {},
      onTagTap: null,
      isOwner: false,
      onEditPost: null,
      isEdited: false,
      showEngagement: false,
      descriptionMaxLines: 0,
    );
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
