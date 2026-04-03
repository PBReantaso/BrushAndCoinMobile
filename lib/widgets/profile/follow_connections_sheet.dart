import 'package:flutter/material.dart';

import '../../navigation/user_profile_navigation.dart';
import '../../services/api_client.dart';

/// Instagram-style bottom sheet: drag handle, close, username title, Followers / Following tabs, user list.
Future<void> showFollowConnectionsSheet({
  required BuildContext context,
  required int userId,
  required String displayUsername,
  int initialTab = 0,
  VoidCallback? onClosed,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _FollowConnectionsSheet(
      profileContext: context,
      sheetContext: sheetContext,
      userId: userId,
      displayUsername: displayUsername,
      initialTab: initialTab,
    ),
  );
  onClosed?.call();
}

class _FollowConnectionsSheet extends StatefulWidget {
  final BuildContext profileContext;
  final BuildContext sheetContext;
  final int userId;
  final String displayUsername;
  final int initialTab;

  const _FollowConnectionsSheet({
    required this.profileContext,
    required this.sheetContext,
    required this.userId,
    required this.displayUsername,
    required this.initialTab,
  });

  @override
  State<_FollowConnectionsSheet> createState() => _FollowConnectionsSheetState();
}

class _FollowConnectionsSheetState extends State<_FollowConnectionsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _api = ApiClient();
  late Future<List<_FollowUser>> _followersFuture;
  late Future<List<_FollowUser>> _followingFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _reload();
  }

  void _reload() {
    _followersFuture = _loadFollowers();
    _followingFuture = _loadFollowing();
  }

  Future<List<_FollowUser>> _loadFollowers() async {
    final raw = await _api.fetchFollowers(widget.userId);
    return raw.map(_FollowUser.fromJson).toList();
  }

  Future<List<_FollowUser>> _loadFollowing() async {
    final raw = await _api.fetchFollowing(widget.userId);
    return raw.map(_FollowUser.fromJson).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const _igBlack = Color(0xFF262626);
  static const _igGray = Color(0xFF8E8E8E);
  static const _igDivider = Color(0xFFDBDBDB);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.88;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC7C7C7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: _igBlack, size: 26),
                  onPressed: () => Navigator.of(widget.sheetContext).pop(),
                ),
                Expanded(
                  child: Text(
                    widget.displayUsername,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _igBlack,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 4),
          TabBar(
            controller: _tabController,
            labelColor: _igBlack,
            unselectedLabelColor: _igGray,
            indicatorColor: _igBlack,
            indicatorWeight: 1,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Followers'),
              Tab(text: 'Following'),
            ],
          ),
          const Divider(height: 1, color: _igDivider),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FollowUserList(
                  profileContext: widget.profileContext,
                  sheetContext: widget.sheetContext,
                  future: _followersFuture,
                  emptyMessage: 'No followers yet.',
                  onRetry: () => setState(() => _followersFuture = _loadFollowers()),
                ),
                _FollowUserList(
                  profileContext: widget.profileContext,
                  sheetContext: widget.sheetContext,
                  future: _followingFuture,
                  emptyMessage: 'Not following anyone yet.',
                  onRetry: () => setState(() => _followingFuture = _loadFollowing()),
                ),
              ],
            ),
          ),
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }
}

class _FollowUser {
  final int id;
  final String username;

  _FollowUser({required this.id, required this.username});

  factory _FollowUser.fromJson(Map<String, dynamic> json) {
    return _FollowUser(
      id: _readInt(json['id']),
      username: (json['username'] as String?)?.trim() ?? '',
    );
  }
}

int _readInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class _FollowUserList extends StatelessWidget {
  final BuildContext profileContext;
  final BuildContext sheetContext;
  final Future<List<_FollowUser>> future;
  final String emptyMessage;
  final VoidCallback onRetry;

  const _FollowUserList({
    required this.profileContext,
    required this.sheetContext,
    required this.future,
    required this.emptyMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_FollowUser>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          final msg = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : snapshot.error.toString();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(msg, textAlign: TextAlign.center),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }
        final users = snapshot.data ?? const <_FollowUser>[];
        if (users.isEmpty) {
          return Center(
            child: Text(
              emptyMessage,
              style: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 14),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(top: 4),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEFEFEF)),
          itemBuilder: (context, index) {
            final u = users[index];
            final name = u.username.isNotEmpty ? u.username : 'User';
            return Material(
              color: Colors.white,
              child: InkWell(
                onTap: () {
                  if (u.id <= 0) return;
                  Navigator.of(sheetContext).pop();
                  pushUserProfile(profileContext, userId: u.id, username: name);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFDBDBDB),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF262626),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF262626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
