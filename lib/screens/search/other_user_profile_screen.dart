import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/content_spacing.dart';
import '../../widgets/profile/follow_connections_sheet.dart';
import '../../widgets/profile/profile_avatar.dart';
import '../../widgets/profile/profile_social_links_row.dart';
import '../../widgets/profile/username_with_private_lock.dart';
import '../communication/commissions/commission_request_screen.dart';
import '../communication/messages/chat_screen.dart';
import '../profile/profile_merch_viewer_screen.dart';
import '../profile/profile_post_viewer_screen.dart';
import '../../widgets/common/report_reason_dialog.dart';
import '../../widgets/profile/profile_merch_tile.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final int userId;
  final String usernameHint;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    required this.usernameHint,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final _api = ApiClient();
  bool _busy = true;
  Object? _error;
  _OtherProfileData? _data;
  int? _myUserId;
  int _activeTab = 0;
  bool _followActionBusy = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final myId = await _api.getCurrentUserId();
      final userJson = await _api.fetchPublicUser(widget.userId);
      final user = userJson['user'];
      var username = widget.usernameHint;
      int followerCount = 0;
      int followingCount = 0;
      var isFollowing = false;
      var isPrivate = false;
      var isLocked = false;
      var socialLinks = ProfileSocialLinksRow.emptyMap();
      var tipsEnabled = false;
      String? tipsUrl;
      String? avatarUrl;
      if (user is Map) {
        final u = (user['username'] as String?)?.trim();
        if (u != null && u.isNotEmpty) username = u;
        followerCount = _readInt(user['followerCount']);
        followingCount = _readInt(user['followingCount']);
        final raw = user['isFollowing'];
        if (raw is bool) {
          isFollowing = raw;
        }
        final privRaw = user['isPrivate'];
        if (privRaw is bool) {
          isPrivate = privRaw;
        }
        final locked = user['isLocked'];
        if (locked is bool) {
          isLocked = locked;
        } else {
          final self = myId != null && myId == widget.userId;
          if (isPrivate && !isFollowing && !self) isLocked = true;
        }
        socialLinks = ProfileSocialLinksRow.parseMap(user['socialLinks']);
        final te = user['tipsEnabled'];
        if (te is bool) tipsEnabled = te;
        final tu = user['tipsUrl'];
        if (tu is String && tu.trim().isNotEmpty) tipsUrl = tu.trim();
        final av = user['avatarUrl'];
        if (av is String && av.trim().isNotEmpty) avatarUrl = av.trim();
      }
      final postsRaw = await _api.fetchUserPosts(widget.userId);
      final posts = postsRaw.map(_OtherPost.fromJson).toList();
      List<_OtherMerch> merchandise = [];
      try {
        final merchRaw = await _api.fetchUserMerchandise(widget.userId);
        merchandise = merchRaw.map(_OtherMerch.fromJson).toList();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _myUserId = myId;
        _data = _OtherProfileData(
          username: username,
          posts: posts,
          merchandise: merchandise,
          followerCount: followerCount,
          followingCount: followingCount,
          isFollowing: isFollowing,
          isPrivate: isPrivate,
          isLocked: isLocked,
          socialLinks: socialLinks,
          tipsEnabled: tipsEnabled,
          tipsUrl: tipsUrl,
          avatarUrl: avatarUrl,
        );
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _busy = false;
      });
    }
  }

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _toggleFollow() async {
    final data = _data;
    if (data == null || _followActionBusy) return;
    final currently = data.isFollowing;
    setState(() => _followActionBusy = true);
    try {
      final json = currently
          ? await _api.unfollowUser(widget.userId)
          : await _api.followUser(widget.userId);
      final fc = _readInt(json['followerCount']);
      var following = false;
      final raw = json['isFollowing'];
      if (raw is bool) following = raw;
      if (!mounted) return;
      setState(() {
        _data = data.copyWith(
          followerCount: fc,
          isFollowing: following,
          isLocked: data.isPrivate && !following && !_isSelf,
        );
        _followActionBusy = false;
      });
      unawaited(_bootstrap());
    } catch (e) {
      if (!mounted) return;
      setState(() => _followActionBusy = false);
      final msg = e is ApiException ? e.message : 'Could not update follow.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  /// App red/black theme (same as primary buttons and accents elsewhere).
  static const Color _kBrandRed = Color(0xFFFF4A4A);

  Future<void> _confirmUnfollow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(
          kScreenHorizontalPadding,
          0,
          kScreenHorizontalPadding,
          16,
        ),
        actionsAlignment: MainAxisAlignment.end,
        title: const Text(
          'Unfollow',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1E),
          ),
        ),
        content: const Text(
          'Are you sure you want to unfollow?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF5C5C66),
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1E),
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: _kBrandRed,
            ),
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _toggleFollow();
    }
  }

  void _onMessage() async {
    try {
      final conversationJson = await _api.startConversation(widget.userId);
      final conversation = Conversation.fromJson(conversationJson);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(conversation: conversation),
        ),
      );
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Could not start conversation.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _onCommission() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommissionRequestScreen(
          artistId: widget.userId,
          artistName: _data?.username ?? widget.usernameHint,
        ),
      ),
    );
  }

  Future<void> _reportUserProfile() async {
    final reason = await showReportReasonDialog(
      context,
      title: 'Report this account?',
    );
    if (!mounted || reason == null) return;
    try {
      final json = await _api.reportUser(userId: widget.userId, reason: reason);
      if (!mounted) return;
      final dup = json['alreadyReported'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dup ? 'You already reported this account.' : 'Thanks — we\'ll review your report.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  bool get _isSelf => _myUserId != null && _myUserId == widget.userId;

  ButtonStyle get _outlinedActionStyle => OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFD7D7DE)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.white,
      );

  Widget _wrapFollowWidth({required bool fullWidth, required Widget child}) {
    final wrapped = SizedBox(height: 38, child: child);
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: wrapped);
    }
    return Expanded(child: wrapped);
  }

  Widget _buildFollowControl({bool fullWidth = false}) {
    final data = _data!;
    if (data.isFollowing) {
      return _wrapFollowWidth(
        fullWidth: fullWidth,
        child: OutlinedButton(
          style: _outlinedActionStyle,
          onPressed: _followActionBusy ? null : _confirmUnfollow,
          child: _followActionBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Following',
                  style: TextStyle(
                    color: Color(0xFF1A1A1E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );
    }
    return _wrapFollowWidth(
      fullWidth: fullWidth,
      child: OutlinedButton(
        style: _outlinedActionStyle,
        onPressed: _followActionBusy ? null : _toggleFollow,
        child: _followActionBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Follow',
                style: TextStyle(
                  color: Color(0xFF1A1A1E),
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildActionRows() {
    if (_isSelf) return const SizedBox.shrink();
    final data = _data!;
    if (data.isLocked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0E0E6)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, color: Color(0xFFFF4A4A), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This account is private. Follow to see posts, send messages, and request commissions.',
                    style: TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF3C3C42)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildFollowControl(fullWidth: true),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildFollowControl(),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 38,
                child: OutlinedButton(
                  style: _outlinedActionStyle,
                  onPressed: _onMessage,
                  child: const Text(
                    'Message',
                    style: TextStyle(
                      color: Color(0xFF1A1A1E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          width: double.infinity,
          child: OutlinedButton(
            style: _outlinedActionStyle,
            onPressed: _onCommission,
            child: const Text(
              'Commission',
              style: TextStyle(
                color: Color(0xFF1A1A1E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BcColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: const BackButton(color: BcColors.ink),
        title: _data != null
            ? UsernameWithPrivateLock(
                username: _data!.username.isNotEmpty ? _data!.username : widget.usernameHint,
                isPrivate: _data!.isPrivate,
                textStyle: bcPushedScreenTitleStyle(context),
                lockSize: 17,
              )
            : Text(
                widget.usernameHint,
                style: bcPushedScreenTitleStyle(context),
              ),
        actions: [
          if (!_busy && _data != null && !_isSelf && _myUserId != null)
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert, color: BcColors.ink),
              onSelected: (value) {
                if (value == 'report') unawaited(_reportUserProfile());
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'report',
                  child: Text('Report'),
                ),
              ],
            ),
        ],
        bottom: const BcAppBarBottomLine(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      final msg = _error is ApiException
          ? (_error as ApiException).message
          : _error.toString();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(msg, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _bootstrap,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final data = _data;
    if (data == null) {
      return const Center(child: Text('Unable to load profile.'));
    }
    final posts = data.posts;
    final merchandise = data.merchandise;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              kScreenHorizontalPadding,
              12,
              kScreenHorizontalPadding,
              10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProfileAvatar(
                      imageUrl: data.avatarUrl,
                      radius: 44,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat(label: 'posts', value: '${posts.length}'),
                          _Stat(
                            label: 'followers',
                            value: '${data.followerCount}',
                            onTap: data.isLocked
                                ? null
                                : () => showFollowConnectionsSheet(
                                      context: context,
                                      userId: widget.userId,
                                      displayUsername: data.username,
                                      initialTab: 0,
                                      onClosed: () {
                                        if (mounted) _bootstrap();
                                      },
                                    ),
                          ),
                          _Stat(
                            label: 'following',
                            value: '${data.followingCount}',
                            onTap: data.isLocked
                                ? null
                                : () => showFollowConnectionsSheet(
                                      context: context,
                                      userId: widget.userId,
                                      displayUsername: data.username,
                                      initialTab: 1,
                                      onClosed: () {
                                        if (mounted) _bootstrap();
                                      },
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                UsernameWithPrivateLock(
                  username: data.username,
                  isPrivate: data.isPrivate,
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1E),
                      ),
                ),
                if (!data.isLocked)
                  ProfileSocialLinksRow(
                    socialLinks: data.socialLinks,
                    tipsEnabled: data.tipsEnabled,
                    tipsUrl: data.tipsUrl,
                  ),
                const SizedBox(height: 8),
                Text(
                  'Bio',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF2C2C2C),
                      ),
                ),
                const SizedBox(height: 10),
                _buildActionRows(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFE6E6EA)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ProfileTextTab(
                          label: 'Gallery',
                          selected: _activeTab == 0,
                          onTap: () => setState(() => _activeTab = 0),
                        ),
                      ),
                      Container(width: 1, height: 20, color: const Color(0xFFD0D0D8)),
                      Expanded(
                        child: _ProfileTextTab(
                          label: 'Merchandise',
                          selected: _activeTab == 1,
                          onTap: () => setState(() => _activeTab = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE6E6EA)),
              ],
            ),
          ),
        ),
        if (_activeTab == 1)
          merchandise.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Text(
                        data.isLocked
                            ? 'Merchandise is hidden for private accounts until you follow.'
                            : 'No merchandise yet.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.only(top: 2),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final m = merchandise[index];
                        return ProfileMerchTile(
                          imageUrl: m.imageUrl,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ProfileMerchViewerScreen(
                                  items: merchandise
                                      .map((e) => e.json)
                                      .toList(),
                                  initialIndex: index,
                                  authorName: data.username,
                                  authorAvatarUrl: data.avatarUrl,
                                  authorUserId: widget.userId,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: merchandise.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: 1,
                    ),
                  ),
                )
        else if (posts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Text(
                  data.isLocked
                      ? 'Posts are hidden for private accounts until you follow.'
                      : 'No posts yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(top: 2),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _GalleryTile(
                  post: posts[index],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProfilePostViewerScreen(
                          posts: posts.map((p) => p.json).toList(),
                          initialIndex: index,
                          currentUserId: _myUserId,
                        ),
                      ),
                    );
                  },
                ),
                childCount: posts.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 1,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

class _OtherProfileData {
  final String username;
  final List<_OtherPost> posts;
  final List<_OtherMerch> merchandise;
  final int followerCount;
  final int followingCount;
  final bool isFollowing;
  final bool isPrivate;
  final bool isLocked;
  final Map<String, String> socialLinks;
  final bool tipsEnabled;
  final String? tipsUrl;
  final String? avatarUrl;

  _OtherProfileData({
    required this.username,
    required this.posts,
    required this.merchandise,
    required this.followerCount,
    required this.followingCount,
    required this.isFollowing,
    required this.isPrivate,
    required this.isLocked,
    required this.socialLinks,
    required this.tipsEnabled,
    this.tipsUrl,
    this.avatarUrl,
  });

  _OtherProfileData copyWith({
    String? username,
    List<_OtherPost>? posts,
    List<_OtherMerch>? merchandise,
    int? followerCount,
    int? followingCount,
    bool? isFollowing,
    bool? isPrivate,
    bool? isLocked,
    Map<String, String>? socialLinks,
    bool? tipsEnabled,
    String? tipsUrl,
    String? avatarUrl,
  }) {
    return _OtherProfileData(
      username: username ?? this.username,
      posts: posts ?? this.posts,
      merchandise: merchandise ?? this.merchandise,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isPrivate: isPrivate ?? this.isPrivate,
      isLocked: isLocked ?? this.isLocked,
      socialLinks: socialLinks ?? this.socialLinks,
      tipsEnabled: tipsEnabled ?? this.tipsEnabled,
      tipsUrl: tipsUrl ?? this.tipsUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class _OtherPost {
  final Map<String, dynamic> json;

  _OtherPost({required this.json});

  factory _OtherPost.fromJson(Map<String, dynamic> j) {
    return _OtherPost(json: Map<String, dynamic>.from(j));
  }

  String? get imageUrl => json['imageUrl'] as String?;
}

class _OtherMerch {
  final Map<String, dynamic> json;

  _OtherMerch({required this.json});

  factory _OtherMerch.fromJson(Map<String, dynamic> j) {
    return _OtherMerch(json: Map<String, dynamic>.from(j));
  }

  String? get imageUrl => json['imageUrl'] as String?;
}

class _GalleryTile extends StatelessWidget {
  final _OtherPost post;
  final VoidCallback onTap;

  const _GalleryTile({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final path = post.imageUrl?.trim() ?? '';
    Widget inner;
    if (path.isNotEmpty) {
      final imageProvider = path.startsWith('http://') || path.startsWith('https://')
          ? NetworkImage(path) as ImageProvider
          : FileImage(File(path));
      inner = Image(
        image: imageProvider,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else {
      inner = _fallback();
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: inner,
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A4B79), Color(0xFF8CA6DB)],
        ),
      ),
      child: const Center(child: Icon(Icons.image, color: Colors.white70)),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _Stat({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1E),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6C6C74),
              ),
        ),
      ],
    );
    if (onTap == null) return column;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: column,
        ),
      ),
    );
  }
}

class _ProfileTextTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileTextTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected ? const Color(0xFFFF3D3D) : const Color(0xFF7B7B84),
                ),
          ),
        ),
      ),
    );
  }
}
