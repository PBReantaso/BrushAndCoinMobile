import 'dart:io';

import 'package:flutter/material.dart';

import '../../navigation/app_route_observer.dart';
import '../../services/api_client.dart';
import '../../state/app_profile_scope.dart';
import '../../theme/content_spacing.dart';
import '../../widgets/common/bc_app_bar.dart';
import '../../widgets/profile/edit_profile_bottom_sheet.dart';
import '../../widgets/profile/follow_connections_sheet.dart';
import '../../widgets/profile/profile_avatar.dart';
import '../../widgets/profile/profile_social_links_row.dart';
import '../../widgets/profile/username_with_private_lock.dart';
import 'profile_merch_viewer_screen.dart';
import 'profile_post_viewer_screen.dart';
import '../../widgets/profile/profile_merch_tile.dart';

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

  Future<void> _pullRefreshProfile() async {
    try {
      final data = await _loadProfile();
      if (!mounted) return;
      setState(() {
        _profileFuture = Future.value(data);
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _profileFuture = Future.error(e, stackTrace);
      });
    }
  }

  Future<_ProfileLoadResult> _loadProfile() async {
    final postsRaw = await _apiClient.fetchMyPosts();
    final meJson = await _apiClient.fetchMe();
    final user = meJson['user'];
    var apiUsername = '';
    var followerCount = 0;
    var followingCount = 0;
    var myUserId = 0;
    var isPrivate = false;
    var firstName = '';
    var lastName = '';
    String? avatarUrl;
    var socialLinks = _emptySocialMap();
    var tipsEnabled = false;
    String? tipsUrl;
    if (user is Map) {
      apiUsername = (user['username'] as String?)?.trim() ?? '';
      followerCount = _readStatInt(user['followerCount']);
      followingCount = _readStatInt(user['followingCount']);
      myUserId = _readStatInt(user['id']);
      final p = user['isPrivate'];
      if (p is bool) isPrivate = p;
      final fn = user['firstName'];
      if (fn is String) firstName = fn.trim();
      final ln = user['lastName'];
      if (ln is String) lastName = ln.trim();
      final av = user['avatarUrl'];
      if (av is String && av.trim().isNotEmpty) avatarUrl = av.trim();
      socialLinks = _parseSocialLinks(user['socialLinks']);
      final te = user['tipsEnabled'];
      if (te is bool) tipsEnabled = te;
      final tu = user['tipsUrl'];
      if (tu is String && tu.trim().isNotEmpty) tipsUrl = tu.trim();
    }
    var merchandise = <_ProfileMerch>[];
    if (myUserId > 0) {
      try {
        final merchRaw = await _apiClient.fetchUserMerchandise(myUserId);
        merchandise = merchRaw.map(_ProfileMerch.fromJson).toList();
      } catch (_) {}
    }
    return _ProfileLoadResult(
      posts: postsRaw.map(_ProfilePost.fromJson).toList(),
      merchandise: merchandise,
      apiUsername: apiUsername,
      followerCount: followerCount,
      followingCount: followingCount,
      myUserId: myUserId,
      isPrivate: isPrivate,
      firstName: firstName,
      lastName: lastName,
      avatarUrl: avatarUrl,
      socialLinks: socialLinks,
      tipsEnabled: tipsEnabled,
      tipsUrl: tipsUrl,
    );
  }

  static Map<String, String> _emptySocialMap() => {
        'facebook': '',
        'instagram': '',
        'twitter': '',
        'website': '',
      };

  static Map<String, String> _parseSocialLinks(dynamic v) {
    const keys = ['facebook', 'instagram', 'twitter', 'website'];
    final out = <String, String>{};
    if (v is Map) {
      for (final k in keys) {
        final x = v[k];
        out[k] = x is String ? x.trim() : '';
      }
      return out;
    }
    return _emptySocialMap();
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
          final merchandise = data?.merchandise ?? const <_ProfileMerch>[];
          final apiUsername = data?.apiUsername ?? '';
          final followerCount = data?.followerCount ?? 0;
          final followingCount = data?.followingCount ?? 0;
          final myUserId = data?.myUserId ?? 0;
          final isPrivate = data?.isPrivate ?? false;
          final apiFirst = data?.firstName ?? '';
          final apiLast = data?.lastName ?? '';
          final fn = (apiFirst.isNotEmpty ? apiFirst : p.firstName).trim();
          final ln = (apiLast.isNotEmpty ? apiLast : p.lastName).trim();
          final handle = apiUsername.isNotEmpty
              ? apiUsername
              : (localUsername.isNotEmpty ? localUsername : '');
          final displayName = (fn.isEmpty && ln.isEmpty)
              ? (handle.isNotEmpty ? handle : 'Name')
              : '$fn $ln'.trim();
          final avatarUrl = data?.avatarUrl ?? p.avatarUrl;
          final postsCount = posts.length;

          return RefreshIndicator(
            color: const Color(0xFFFF4A4A),
            onRefresh: _pullRefreshProfile,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    kScreenHorizontalPadding,
                    12 + kContentBelowAppBarPadding,
                    kScreenHorizontalPadding,
                    10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ProfileAvatar(imageUrl: avatarUrl, radius: 44),
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
                                            displayUsername: displayName,
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
                                            displayUsername: displayName,
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
                      UsernameWithPrivateLock(
                        username: displayName,
                        isPrivate: isPrivate,
                        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1A1E),
                            ),
                      ),
                      if (handle.isNotEmpty && displayName != handle)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '@$handle',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF6C6C74),
                                  fontWeight: FontWeight.w600,
                                ),
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
                      ProfileSocialLinksRow(
                        socialLinks: data?.socialLinks ?? ProfileSocialLinksRow.emptyMap(),
                        tipsEnabled: data?.tipsEnabled ?? false,
                        tipsUrl: data?.tipsUrl,
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
                                onPressed: snapshot.connectionState == ConnectionState.waiting
                                    ? null
                                    : () async {
                                        final saved = await showEditProfileBottomSheet(
                                          context,
                                          initialUsername: handle.isNotEmpty
                                              ? handle
                                              : (localUsername.isNotEmpty ? localUsername : ''),
                                          initialFirstName: fn,
                                          initialLastName: ln,
                                          initialAvatarUrl: avatarUrl,
                                          initialSocialLinks: data?.socialLinks,
                                          initialTipsEnabled: data?.tipsEnabled ?? false,
                                          initialTipsUrl: data?.tipsUrl,
                                        );
                                        if (saved && context.mounted) {
                                          _refreshProfile();
                                        }
                                      },
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
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData &&
                  !snapshot.hasError)
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
                merchandise.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: Center(
                            child: Text('No merchandise yet.'),
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
                                        authorName: displayName,
                                        authorAvatarUrl: avatarUrl,
                                        authorUserId: myUserId,
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
                      (context, index) => _GalleryTile(
                        post: posts[index],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ProfilePostViewerScreen(
                                posts: posts.map((p) => p.json).toList(),
                                initialIndex: index,
                                currentUserId:
                                    myUserId > 0 ? myUserId : null,
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
            ),
          );
        },
      ),
    );
  }
}

class _ProfileLoadResult {
  final List<_ProfilePost> posts;
  final List<_ProfileMerch> merchandise;
  final String apiUsername;
  final int followerCount;
  final int followingCount;
  final int myUserId;
  final bool isPrivate;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final Map<String, String> socialLinks;
  final bool tipsEnabled;
  final String? tipsUrl;

  const _ProfileLoadResult({
    required this.posts,
    required this.merchandise,
    required this.apiUsername,
    required this.followerCount,
    required this.followingCount,
    required this.myUserId,
    required this.isPrivate,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.socialLinks,
    required this.tipsEnabled,
    required this.tipsUrl,
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
  final Map<String, dynamic> json;

  const _ProfilePost({required this.json});

  factory _ProfilePost.fromJson(Map<String, dynamic> j) {
    return _ProfilePost(json: Map<String, dynamic>.from(j));
  }

  String? get imageUrl => json['imageUrl'] as String?;
}

class _ProfileMerch {
  final Map<String, dynamic> json;

  const _ProfileMerch({required this.json});

  factory _ProfileMerch.fromJson(Map<String, dynamic> j) {
    return _ProfileMerch(json: Map<String, dynamic>.from(j));
  }

  String? get imageUrl => json['imageUrl'] as String?;
}

class _GalleryTile extends StatelessWidget {
  final _ProfilePost post;
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

