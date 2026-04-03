import 'dart:io';

import 'package:flutter/material.dart';

import '../../navigation/app_route_observer.dart';
import '../../services/api_client.dart';
import '../../state/app_profile_scope.dart';
import '../../theme/content_spacing.dart';
import '../../widgets/common/bc_app_bar.dart';
import '../../widgets/profile/follow_connections_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  int _activeTab = 0; // 0 Gallery, 1 Merchandise
  final _apiClient = ApiClient();
  late Future<_ProfileLoadResult> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshProfile();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  Future<_ProfileLoadResult> _loadProfile() async {
    final postsRaw = await _apiClient.fetchMyPosts();
    final meJson = await _apiClient.fetchMe();
    final user = meJson['user'];
    var apiUsername = '';
    var followerCount = 0;
    var followingCount = 0;
    var myUserId = 0;
    if (user is Map) {
      apiUsername = (user['username'] as String?)?.trim() ?? '';
      followerCount = _readStatInt(user['followerCount']);
      followingCount = _readStatInt(user['followingCount']);
      myUserId = _readStatInt(user['id']);
    }
    return _ProfileLoadResult(
      posts: postsRaw.map(_ProfilePost.fromJson).toList(),
      apiUsername: apiUsername,
      followerCount: followerCount,
      followingCount: followingCount,
      myUserId: myUserId,
    );
  }

  int _readStatInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = AppProfileScope.of(context);
    final p = profileState.profile;
    final localUsername = p.username.trim();

    final genderRaw = p.gender.name; // enum -> 'male' | 'female' | ...
    final genderLabel = switch (genderRaw) {
      'male' => 'Male',
      'female' => 'Female',
      'other' => 'Other',
      'preferNotToSay' => 'Prefer not to say',
      _ => '',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      appBar: const BcAppBar(),
      body: FutureBuilder<_ProfileLoadResult>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final posts = data?.posts ?? const <_ProfilePost>[];
          final apiUsername = data?.apiUsername ?? '';
          final followerCount = data?.followerCount ?? 0;
          final followingCount = data?.followingCount ?? 0;
          final myUserId = data?.myUserId ?? 0;
          final headerName = apiUsername.isNotEmpty
              ? apiUsername
              : (localUsername.isNotEmpty ? localUsername : 'Name');
          final postsCount = posts.length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12 + kContentBelowAppBarPadding,
                    16,
                    10,
                  ),
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
                                _Stat(label: 'posts', value: '$postsCount'),
                                _Stat(
                                  label: 'followers',
                                  value: '$followerCount',
                                  onTap: myUserId > 0
                                      ? () => showFollowConnectionsSheet(
                                            context: context,
                                            userId: myUserId,
                                            displayUsername: headerName,
                                            initialTab: 0,
                                            onClosed: _refreshProfile,
                                          )
                                      : null,
                                ),
                                _Stat(
                                  label: 'following',
                                  value: '$followingCount',
                                  onTap: myUserId > 0
                                      ? () => showFollowConnectionsSheet(
                                            context: context,
                                            userId: myUserId,
                                            displayUsername: headerName,
                                            initialTab: 1,
                                            onClosed: _refreshProfile,
                                          )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        headerName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1A1E),
                            ),
                      ),
                      if (genderLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            genderLabel,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6C6C74),
                                ),
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
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFD7D7DE)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                                onPressed: () {},
                                child: const Text(
                                  'Edit profile',
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
                              onPressed: () {},
                              child: const Icon(Icons.person_add_alt_1, size: 18),
                            ),
                          ),
                        ],
                      ),
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
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (snapshot.hasError)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: TextButton(
                        onPressed: () => setState(() => _profileFuture = _loadProfile()),
                        child: const Text('Failed to load posts. Tap to retry.'),
                      ),
                    ),
                  ),
                )
              else if (_activeTab == 1)
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
                    child: Center(child: Text('No posts yet. Create your first post.')),
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
        },
      ),
    );
  }
}

class _ProfileLoadResult {
  final List<_ProfilePost> posts;
  final String apiUsername;
  final int followerCount;
  final int followingCount;
  final int myUserId;

  const _ProfileLoadResult({
    required this.posts,
    required this.apiUsername,
    required this.followerCount,
    required this.followingCount,
    required this.myUserId,
  });
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
    if (onTap == null) {
      return column;
    }
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

class _ProfilePost {
  final String? imageUrl;

  const _ProfilePost({required this.imageUrl});

  factory _ProfilePost.fromJson(Map<String, dynamic> json) {
    return _ProfilePost(imageUrl: json['imageUrl'] as String?);
  }
}

class _GalleryTile extends StatelessWidget {
  final _ProfilePost post;

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

