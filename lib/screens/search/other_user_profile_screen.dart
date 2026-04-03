import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../services/api_client.dart';
import '../../widgets/profile/follow_connections_sheet.dart';
import '../communication/commissions/commission_request_screen.dart';
import '../communication/messages/chat_screen.dart';

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
      if (user is Map) {
        final u = (user['username'] as String?)?.trim();
        if (u != null && u.isNotEmpty) username = u;
        followerCount = _readInt(user['followerCount']);
        followingCount = _readInt(user['followingCount']);
        final raw = user['isFollowing'];
        if (raw is bool) {
          isFollowing = raw;
        }
      }
      final postsRaw = await _api.fetchUserPosts(widget.userId);
      final posts = postsRaw.map(_OtherPost.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _myUserId = myId;
        _data = _OtherProfileData(
          username: username,
          posts: posts,
          followerCount: followerCount,
          followingCount: followingCount,
          isFollowing: isFollowing,
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
        _data = data.copyWith(followerCount: fc, isFollowing: following);
        _followActionBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _followActionBusy = false);
      final msg = e is ApiException ? e.message : 'Could not update follow.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

  void _onTip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tips are coming soon.')),
    );
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

  bool get _isSelf => _myUserId != null && _myUserId == widget.userId;

  ButtonStyle get _outlinedActionStyle => OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFD7D7DE)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.white,
      );

  Widget _buildFollowControl() {
    final data = _data!;
    if (data.isFollowing) {
      return Expanded(
        child: SizedBox(
          height: 38,
          child: PopupMenuButton<String>(
            offset: const Offset(0, 38),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (value) {
              if (value == 'unfollow') _toggleFollow();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'unfollow',
                child: Text('Unfollow'),
              ),
            ],
            child: Container(
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD7D7DE)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Following',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1E),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.expand_more, size: 18, color: Color(0xFF1A1A1E)),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Expanded(
      child: SizedBox(
        height: 38,
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
      ),
    );
  }

  Widget _buildActionRows() {
    if (_isSelf) return const SizedBox.shrink();
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
            const SizedBox(width: 10),
            SizedBox(
              height: 38,
              width: 42,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD7D7DE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                onPressed: _onTip,
                child: const Icon(Icons.attach_money, size: 22, color: Color(0xFFFF4A4A)),
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
      backgroundColor: const Color(0xFFF2F2F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDF1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _data?.username ?? widget.usernameHint,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 44,
                      backgroundColor: Color(0xFFD8D8DE),
                      child: Icon(Icons.person, color: Color(0xFF6D6D75), size: 34),
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
                            onTap: () => showFollowConnectionsSheet(
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
                            onTap: () => showFollowConnectionsSheet(
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
                Text(
                  data.username,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1E),
                      ),
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
          SliverPadding(
            padding: const EdgeInsets.only(top: 2),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  const colors = [
                    [Color(0xFF6F4E37), Color(0xFFD4A373)],
                    [Color(0xFF2F3E46), Color(0xFF84A98C)],
                    [Color(0xFF4A4E69), Color(0xFF9A8C98)],
                    [Color(0xFF5F0F40), Color(0xFF9A031E)],
                  ];
                  final palette = colors[index % colors.length];
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: palette,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 32),
                    ),
                  );
                },
                childCount: 4,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 1,
              ),
            ),
          )
        else if (posts.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('No posts yet.')),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(top: 2),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _GalleryTile(post: posts[index]),
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
  final int followerCount;
  final int followingCount;
  final bool isFollowing;

  _OtherProfileData({
    required this.username,
    required this.posts,
    required this.followerCount,
    required this.followingCount,
    required this.isFollowing,
  });

  _OtherProfileData copyWith({
    String? username,
    List<_OtherPost>? posts,
    int? followerCount,
    int? followingCount,
    bool? isFollowing,
  }) {
    return _OtherProfileData(
      username: username ?? this.username,
      posts: posts ?? this.posts,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class _OtherPost {
  final String? imageUrl;

  _OtherPost({required this.imageUrl});

  factory _OtherPost.fromJson(Map<String, dynamic> json) {
    return _OtherPost(imageUrl: json['imageUrl'] as String?);
  }
}

class _GalleryTile extends StatelessWidget {
  final _OtherPost post;

  const _GalleryTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final path = post.imageUrl?.trim() ?? '';
    if (path.isNotEmpty) {
      final imageProvider = path.startsWith('http://') || path.startsWith('https://')
          ? NetworkImage(path) as ImageProvider
          : FileImage(File(path));
      return ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
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
