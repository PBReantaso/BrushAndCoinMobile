import 'package:flutter/material.dart';

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';
import '../commissions/commission_detail_screen.dart';
import '../commissions/commission_work_view_screen.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  /// When set, thread is scoped to this commission; messaging closes when status is completed.
  final int? commissionId;

  const ChatScreen({
    super.key,
    required this.conversation,
    this.commissionId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _apiClient = ApiClient();
  final _messageController = TextEditingController();
  Future<List<Message>>? _messagesFuture;
  final ScrollController _scrollController = ScrollController();
  int? _currentUserId;
  late Conversation _conversation;
  bool _commissionMessagingClosed = false;
  bool _commissionStatusLoaded = false;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _loadCurrentUserId();
    _messagesFuture = _loadMessages();
    _loadCommissionMessagingState();
  }

  Future<void> _loadCommissionMessagingState() async {
    final cid = widget.commissionId;
    if (cid == null) {
      if (mounted) setState(() => _commissionStatusLoaded = true);
      return;
    }
    try {
      final json = await _apiClient.fetchCommission(cid);
      final status = (json['status'] as String?) ?? '';
      if (!mounted) return;
      setState(() {
        _commissionMessagingClosed = status == 'completed';
        _commissionStatusLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _commissionStatusLoaded = true);
    }
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await _apiClient.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Message>> _loadMessages() async {
    final items = await _apiClient.fetchConversationMessages(widget.conversation.id!);
    final messages = items.map(Message.fromJson).toList();
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<void> _sendMessage() async {
    if (_commissionMessagingClosed) return;
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    try {
      await _apiClient.sendMessage(widget.conversation.id!, content);
      setState(() {
        _messagesFuture = _loadMessages();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  String _chatPeerDisplayName() {
    final n = _conversation.name.trim();
    if (n.isEmpty) return '@…';
    return n.startsWith('@') ? n : '@$n';
  }

  Future<void> _openCommissionDetailsFromChat() async {
    final id = widget.commissionId;
    if (id == null) return;
    try {
      final j = await _apiClient.fetchCommission(id);
      if (!mounted) return;
      final p = Project.fromJson(j);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommissionDetailScreen(commission: p),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load commission: $e')),
      );
    }
  }

  Future<void> _openWorkViewFromChat(String stageKey) async {
    final id = widget.commissionId;
    if (id == null) return;
    try {
      final j = await _apiClient.fetchCommission(id);
      if (!mounted) return;
      final p = Project.fromJson(j);
      final patronReview = _currentUserId != null &&
          p.patronId == _currentUserId &&
          p.status == ProjectStatus.inProgress;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CommissionWorkViewScreen(
            commission: p,
            workStageKey: stageKey,
            patronReviewMode: patronReview,
          ),
        ),
      );
      if (result == true && mounted) {
        await _loadCommissionMessagingState();
        setState(() => _messagesFuture = _loadMessages());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open work: $e')),
      );
    }
  }

  PreferredSizeWidget _buildCommissionAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(104),
      child: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _chatPeerDisplayName(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDF1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Commission No#${widget.commissionId}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF444444),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                    icon: const Icon(Icons.visibility_outlined, size: 22),
                    onPressed: _openCommissionDetailsFromChat,
                    tooltip: 'View commission details',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.commissionId != null
          ? _buildCommissionAppBar()
          : AppBar(
              title: Text(_conversation.name),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
      body: Column(
        children: [
          if (widget.commissionId != null && _commissionMessagingClosed) ...[
            Material(
              color: const Color(0xFFE8F5E9),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Commission #${widget.commissionId} is completed. You can read messages but can’t send new ones.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF1B5E20),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          Expanded(
            child: FutureBuilder<List<Message>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _messagesFuture = _loadMessages();
                        });
                      },
                      child: const Text('Retry loading messages'),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Start a conversation',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    final ws = _parseWorkSubmitted(message.content);
                    if (ws != null) {
                      return _WorkSubmittedBubble(
                        stageKey: ws.$1,
                        artistName: ws.$2,
                        onViewWork: () => _openWorkViewFromChat(ws.$1),
                      );
                    }
                    if (_isCompletionSystemLine(message.content)) {
                      return _SystemMessageBubble(text: message.content);
                    }
                    return _MessageBubble(message: message, isMe: isMe);
                  },
                );
              },
            ),
          ),
          if (!_commissionMessagingClosed)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: _commissionStatusLoaded,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _commissionStatusLoaded ? _sendMessage : null,
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

(String stageKey, String artistName)? _parseWorkSubmitted(String content) {
  final t = content.trim();
  if (!t.startsWith('WORK_SUBMITTED|')) return null;
  final parts = t.split('|');
  if (parts.length < 3) return null;
  return (parts[1], parts.sublist(2).join('|'));
}

bool _isCompletionSystemLine(String content) {
  final t = content.trim();
  return t.startsWith('Commission No#') && t.toLowerCase().contains('completed');
}

class _WorkSubmittedBubble extends StatelessWidget {
  final String stageKey;
  final String artistName;
  final VoidCallback onViewWork;

  const _WorkSubmittedBubble({
    required this.stageKey,
    required this.artistName,
    required this.onViewWork,
  });

  static String _stageLabel(String key) {
    switch (key) {
      case 'second':
        return 'Second work';
      case 'last':
        return 'Last work';
      default:
        return 'First work';
    }
  }

  @override
  Widget build(BuildContext context) {
    final handle = artistName.startsWith('@') ? artistName : '@$artistName';
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF555555),
          fontWeight: FontWeight.w500,
          height: 1.35,
        );
    final linkStyle = baseStyle?.copyWith(
      color: const Color(0xFFD32F2F),
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Column(
          children: [
            Row(children: [Expanded(child: Divider(color: Colors.grey.shade300))]),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '$handle have submitted ${_stageLabel(stageKey)}. ',
                    textAlign: TextAlign.center,
                    style: baseStyle,
                  ),
                  GestureDetector(
                    onTap: onViewWork,
                    child: Text('View Work', style: linkStyle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemMessageBubble extends StatelessWidget {
  final String text;

  const _SystemMessageBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF444444),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isMe ? Colors.white : Colors.black,
                fontWeight: FontWeight.w400,
              ),
        ),
      ),
    );
  }
}
