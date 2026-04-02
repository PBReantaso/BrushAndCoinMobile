import 'package:flutter/material.dart';

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';
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
    return items.map(Conversation.fromJson).toList();
  }

  List<Color> _avatarColors = const [
    Color(0xFFFF4A4A),
    Color(0xFF111111),
    Color(0xFF6B4E3D),
    Color(0xFF8A6D5A),
  ];

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Today, show time
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'pm' : 'am'}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
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
            return Center(
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _conversationsFuture = _loadConversations();
                  });
                },
                child: const Text('Retry loading messages'),
              ),
            );
          }

          final conversations = snapshot.data ?? const <Conversation>[];

          if (conversations.isEmpty) {
            return const Center(child: Text('No messages yet.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _conversationsFuture = _loadConversations();
              });
            },
            child: ListView.builder(
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
                      setState(() {
                        _readMessageIndexes.add(index);
                      });
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(conversation: convo),
                        ),
                      );
                      // Refresh after returning from chat
                      setState(() {
                        _conversationsFuture = _loadConversations();
                      });
                    },
                    child: _ConversationCard(
                      name: convo.name,
                      snippet: snippet,
                      dateLabel: dateLabel,
                      avatarColor: avatarColor,
                      isRead: _readMessageIndexes.contains(index),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  snippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6E6E6E),
                    height: 1.2,
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
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9B9B9F),
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
