import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';
import '../../../state/inbox_badge_scope.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _apiClient = ApiClient();
  late Future<List<Conversation>> _conversationsFuture;

  // Simple in-memory tracking of which message indices have been read.
  final Set<int> _readMessageIndexes = {};

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

  List<Color> _avatarColors = const [
    Color(0xFFFF4A4A),
    Color(0xFF111111),
    Color(0xFF6B4E3D),
    Color(0xFF8A6D5A),
  ];

  String _formatDate(tz.TZDateTime date) {
    final phLocation = tz.getLocation('Asia/Manila');
    final now = tz.TZDateTime.now(phLocation);
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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

          final conversations = snapshot.data ?? const <Conversation>[];

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
                      child: const Center(child: Text('No messages yet.')),
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
                final avatarColor = _avatarColors[index % _avatarColors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () async {
                      final scope = InboxBadgeScope.maybeOf(context);
                      setState(() {
                        _readMessageIndexes.add(index);
                      });
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
                    child: _ConversationCard(
                      name: convo.name,
                      snippet: snippet,
                      dateLabel: dateLabel,
                      avatarColor: avatarColor,
                      isRead: !convo.hasUnreadMessages ||
                          _readMessageIndexes.contains(index),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final String name;
  final String snippet;
  final String dateLabel;
  final Color avatarColor;
  final bool isRead;

  const _ConversationCard({
    required this.name,
    required this.snippet,
    required this.dateLabel,
    required this.avatarColor,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: avatarColor,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF9B9B9F),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            width: 6,
            height: 76,
            decoration: BoxDecoration(
              color: isRead ? const Color(0xFF101010) : const Color(0xFFFF4A4A),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
