import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/content_spacing.dart';
import '../../../state/inbox_badge_scope.dart';
import '../../../widgets/profile/profile_avatar.dart';
import 'chat_screen.dart';

enum _MessageInboxFilter { all, unread, read }

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _apiClient = ApiClient();
  late Future<List<Conversation>> _conversationsFuture;
  _MessageInboxFilter _inboxFilter = _MessageInboxFilter.all;

  /// Opened conversations; list order changes so we key by conversation id, not index.
  final Set<int> _optimisticReadConversationIds = {};

  @override
  void initState() {
    super.initState();
    _conversationsFuture = _loadConversations();
  }

  Future<List<Conversation>> _loadConversations() async {
    final items = await _apiClient.fetchMessages();
    final conversations = items.map(Conversation.fromJson).toList();

    // Sort by last message date descending (newest first)
    conversations.sort((a, b) {
      final aDate = a.lastMessageDate;
      final bDate = b.lastMessageDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    // Deduplicate by ID and name to avoid showing the same person multiple times.
    final seenIds = <int>{};
    final seenNames = <String>{};
    final unique = <Conversation>[];

    for (final convo in conversations) {
      final id = convo.id;
      final name = convo.name.trim();

      // Hide non-existing or unnamed user conversations.
      if (name.isEmpty) continue;

      if (id != null && seenIds.contains(id)) continue;
      if (seenNames.contains(name)) continue;

      if (id != null) seenIds.add(id);
      seenNames.add(name);

      unique.add(convo);
    }

    return unique;
  }

  bool _effectiveUnread(Conversation c) {
    final optimistic =
        c.id != null && _optimisticReadConversationIds.contains(c.id!);
    return c.hasUnreadMessages && !optimistic;
  }

  List<Conversation> _applyInboxFilter(List<Conversation> list) {
    switch (_inboxFilter) {
      case _MessageInboxFilter.all:
        return list;
      case _MessageInboxFilter.unread:
        return list.where(_effectiveUnread).toList();
      case _MessageInboxFilter.read:
        return list.where((c) => !_effectiveUnread(c)).toList();
    }
  }

  /// 12h time in the same zone as [date] (Manila for API timestamps).
  String _formatTime12h(tz.TZDateTime date) {
    var h = date.hour;
    final m = date.minute;
    final isPm = h >= 12;
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    final mm = m.toString().padLeft(2, '0');
    final suffix = isPm ? 'pm' : 'am';
    return '$h:$mm $suffix';
  }

  String _formatDate(tz.TZDateTime date) {
    final phLocation = tz.getLocation('Asia/Manila');
    final now = tz.TZDateTime.now(phLocation);
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return _formatTime12h(date);
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  Future<void> _reloadConversations() async {
    final f = _loadConversations();
    setState(() {
      _conversationsFuture = f;
    });
    await f;
  }

  Future<void> _onPullRefresh() async {
    await _reloadConversations();
    if (!mounted) return;
    InboxBadgeScope.maybeOf(context)?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kScreenHorizontalPadding,
        8,
        kScreenHorizontalPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Messages',
                style: t.titleMedium?.copyWith(
                  color: BcColors.brandRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Theme(
                data: Theme.of(context).copyWith(
                  highlightColor: const Color(0xFFFFE4E4),
                  splashColor: const Color(0x26FF4A4A),
                ),
                child: PopupMenuButton<_MessageInboxFilter>(
                  tooltip: 'Filter messages',
                  initialValue: _inboxFilter,
                  onSelected: (mode) => setState(() => _inboxFilter = mode),
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 6),
                  elevation: 10,
                  shadowColor: Colors.black.withValues(alpha: 0.14),
                  surfaceTintColor: Colors.transparent,
                  color: Colors.white,
                  menuPadding: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  constraints: const BoxConstraints(minWidth: 188),
                  popUpAnimationStyle: AnimationStyle.noAnimation,
                  itemBuilder: (menuContext) {
                    final m = Theme.of(menuContext).textTheme;
                    final itemStyle = m.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF222222),
                    );
                    return [
                      PopupMenuItem(
                        value: _MessageInboxFilter.all,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('All', style: itemStyle),
                      ),
                      PopupMenuItem(
                        value: _MessageInboxFilter.unread,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('Unread', style: itemStyle),
                      ),
                      PopupMenuItem(
                        value: _MessageInboxFilter.read,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('Read', style: itemStyle),
                      ),
                    ];
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(
                      Icons.filter_list,
                      color: Colors.black.withValues(alpha: 0.75),
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<Conversation>>(
              future: _conversationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return RefreshIndicator(
                    color: const Color(0xFFFF4A4A),
                    onRefresh: _onPullRefresh,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: FilledButton(
                                onPressed: () {
                                  setState(() {
                                    _conversationsFuture = _loadConversations();
                                  });
                                },
                                child: const Text('Retry loading messages'),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                final loaded = snapshot.data ?? const <Conversation>[];
                final conversations = _applyInboxFilter(loaded);

                if (loaded.isEmpty) {
                  return RefreshIndicator(
                    color: const Color(0xFFFF4A4A),
                    onRefresh: _onPullRefresh,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minHeight: constraints.maxHeight),
                            child: const Center(child: Text('No messages yet.')),
                          ),
                        );
                      },
                    ),
                  );
                }

                if (conversations.isEmpty) {
                  return RefreshIndicator(
                    color: const Color(0xFFFF4A4A),
                    onRefresh: _onPullRefresh,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: Text(
                                'No conversations match this filter.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF6E6E6E),
                                    ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFFFF4A4A),
                  onRefresh: _onPullRefresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final convo = conversations[index];
                      final snippet = convo.lastMessage ?? 'No message yet';
                      final dateLabel = convo.lastMessageDate != null
                          ? _formatDate(convo.lastMessageDate!)
                          : '—';

                      final isRead = !convo.hasUnreadMessages ||
                          (convo.id != null &&
                              _optimisticReadConversationIds.contains(convo.id!));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ConversationCard(
                          avatarUrl: convo.otherUserAvatarUrl,
                          name: convo.name,
                          snippet: snippet,
                          dateLabel: dateLabel,
                          isRead: isRead,
                          onTap: () async {
                            final scope = InboxBadgeScope.maybeOf(context);
                            final cid = convo.id;
                            if (cid != null) {
                              setState(() {
                                _optimisticReadConversationIds.add(cid);
                              });
                            }
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(conversation: convo),
                              ),
                            );
                            if (!mounted) return;
                            scope?.refresh();
                            setState(() {
                              _conversationsFuture = _loadConversations();
                            });
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  static const _unreadBg = Color(0xFFFFF0F0);
  static const _unreadBar = Color(0xFFFF9A9A);
  static const _readBg = Color(0xFFFFFFFF);
  static const _readBar = Color(0xFFB0B0B6);

  final String? avatarUrl;
  final String name;
  final String snippet;
  final String dateLabel;
  final bool isRead;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.avatarUrl,
    required this.name,
    required this.snippet,
    required this.dateLabel,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isRead ? _readBg : _unreadBg;
    final bar = isRead ? _readBar : _unreadBar;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: bg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileAvatar(
                            imageUrl: avatarUrl,
                            radius: 22,
                            placeholderBackgroundColor: const Color(0xFFFF4A4A),
                            placeholderIconColor: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                        color: const Color(0xFF111111),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  snippet,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFF6E6E6E),
                                        height: 1.2,
                                        fontWeight: FontWeight.w400,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              dateLabel,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF9B9B9F),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 7,
                    color: bar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
