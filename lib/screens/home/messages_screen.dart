import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../services/api_client.dart';
import '../../widgets/common/bc_app_bar.dart';

enum _CommissionFilter { all, pending, accepted, inProgress, completed }

class _CommissionRequest {
  final String name;
  final String message;
  final String dateLabel;
  final String statusLabel;
  final _CommissionFilter status;

  // Visual accents to mimic the UI style in the screenshots.
  final Color backgroundColor;
  final Color sideBarColor;

  const _CommissionRequest({
    required this.name,
    required this.message,
    required this.dateLabel,
    required this.statusLabel,
    required this.status,
    required this.backgroundColor,
    required this.sideBarColor,
  });
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _apiClient = ApiClient();
  late Future<List<Conversation>> _conversationsFuture;

  bool _showCommissionRequests = false;
  _CommissionFilter _filter = _CommissionFilter.all;

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

  List<_CommissionRequest> _commissionRequests() {
    // Note: API conversations currently only contains `name`, so these
    // request cards are UI placeholders to match your screenshot layout.
    return const [
      _CommissionRequest(
        name: 'Michael',
        message: 'See the commission request below.',
        dateLabel: '03/19/2026',
        statusLabel: 'Pending',
        status: _CommissionFilter.pending,
        backgroundColor: Colors.white,
        sideBarColor: Color(0xFFFF4A4A),
      ),
      _CommissionRequest(
        name: 'Donatello',
        message: 'My rat splinter likes your art',
        dateLabel: '03/17/2026',
        statusLabel: 'Accepted',
        status: _CommissionFilter.accepted,
        backgroundColor: Colors.white,
        sideBarColor: Color(0xFFFF4A4A),
      ),
      _CommissionRequest(
        name: 'Leonardo',
        message: '6×7 canvas?',
        dateLabel: '9:41 pm',
        statusLabel: 'In progress',
        status: _CommissionFilter.inProgress,
        backgroundColor: Color(0xFFFFE9E9),
        sideBarColor: Color(0xFFFF4A4A),
      ),
      _CommissionRequest(
        name: 'Raphael',
        message: 'The commission was successful',
        dateLabel: '02/17/2026',
        statusLabel: 'Completed',
        status: _CommissionFilter.completed,
        backgroundColor: Colors.white,
        sideBarColor: Color(0xFF101010),
      ),
      _CommissionRequest(
        name: 'Zoro',
        message: 'The commission failed',
        dateLabel: '02/17/2026',
        statusLabel: 'Failed',
        status: _CommissionFilter.all,
        backgroundColor: Color(0xFFF3F3F6),
        sideBarColor: Color(0xFF2A2A2A),
      ),
    ];
  }

  bool _matchesFilter(_CommissionRequest item) {
    if (_filter == _CommissionFilter.all) return true;
    // Only the four screenshot filters are mapped; "Failed" is shown only in All.
    if (item.status == _CommissionFilter.all) return false;
    return item.status == _filter;
  }

  List<String> _messageSnippets = const [
    'Can I commission snake pasta art?',
    'I love myself. Can u draw me?',
    "I'm just a man",
    'I’m sorry because I am lost',
  ];

  List<String> _messageDateLabels = const [
    '7:47 pm',
    '6:07 pm',
    '02/17/2026',
    '02/17/2026',
  ];

  List<Color> _avatarColors = const [
    Color(0xFFFF4A4A),
    Color(0xFF111111),
    Color(0xFF6B4E3D),
    Color(0xFF8A6D5A),
  ];

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF4A4A);
    return Scaffold(
      appBar: const BcAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      backgroundColor:
                          _showCommissionRequests ? Colors.white : accent,
                      textColor: _showCommissionRequests ? Colors.black : Colors.white,
                      label: 'Messages',
                      isActive: !_showCommissionRequests,
                      onTap: () => setState(() => _showCommissionRequests = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeButton(
                      backgroundColor:
                          _showCommissionRequests ? accent : Colors.white,
                      textColor:
                          _showCommissionRequests ? Colors.white : Colors.black,
                      label: 'Commission Requests',
                      isActive: _showCommissionRequests,
                      onTap: () => setState(() => _showCommissionRequests = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_showCommissionRequests) ...[
                _StatusFilterRow(
                  active: _filter,
                  onChanged: (v) => setState(() => _filter = v),
                ),
                const SizedBox(height: 12),
              ],

              Expanded(
                child: _showCommissionRequests
                    ? ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _commissionRequests().where(_matchesFilter).length,
                        itemBuilder: (context, index) {
                          final items =
                              _commissionRequests().where(_matchesFilter).toList();
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CommissionCard(request: item),
                          );
                        },
                      )
                    : FutureBuilder<List<Conversation>>(
                        future: _conversationsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
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

                          final conversations =
                              snapshot.data ?? const <Conversation>[];

                          if (conversations.isEmpty) {
                            return const Center(child: Text('No messages yet.'));
                          }

                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: conversations.length,
                            itemBuilder: (context, index) {
                              final convo = conversations[index];
                              final snippet =
                                  index < _messageSnippets.length
                                      ? _messageSnippets[index]
                                      : 'No message yet';
                              final dateLabel =
                                  index < _messageDateLabels.length
                                      ? _messageDateLabels[index]
                                      : '—';
                              final avatarColor =
                                  index < _avatarColors.length
                                      ? _avatarColors[index]
                                      : accent;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _readMessageIndexes.add(index);
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
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.backgroundColor,
    required this.textColor,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  final _CommissionFilter active;
  final ValueChanged<_CommissionFilter> onChanged;

  const _StatusFilterRow({
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      _CommissionFilter.all,
      _CommissionFilter.pending,
      _CommissionFilter.accepted,
      _CommissionFilter.inProgress,
      _CommissionFilter.completed,
    ];

    final labels = <_CommissionFilter, String>{
      _CommissionFilter.all: 'All',
      _CommissionFilter.pending: 'Pending',
      _CommissionFilter.accepted: 'Accepted',
      _CommissionFilter.inProgress: 'In progress',
      _CommissionFilter.completed: 'Completed',
    };

    return SizedBox(
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDF1),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(6),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: options.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final opt = options[index];
            final selected = opt == active;
            return GestureDetector(
              onTap: () => onChanged(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFF4A4A) : const Color(0xFFF3F3F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    labels[opt]!,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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

class _CommissionCard extends StatelessWidget {
  final _CommissionRequest request;

  const _CommissionCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: request.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.black12,
            child: const Icon(Icons.account_circle_rounded,
                color: Color(0xFF111111), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.message,
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
                request.dateLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9B9B9F),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                request.statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: request.statusLabel == 'Pending'
                      ? Colors.black
                      : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            width: 6,
            height: 76,
            decoration: BoxDecoration(
              color: request.sideBarColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
