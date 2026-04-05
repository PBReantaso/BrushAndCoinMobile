import 'package:flutter/material.dart';

import '../../../models/app_models.dart';
import '../../../services/api_client.dart';
import '../../../widgets/communication/chat_message_content.dart';
import 'commission_detail_screen.dart';
import 'commission_work_view_screen.dart';

const Color _kCommissionSubheaderBg = Color(0xFFEDEDF1);

class CommissionChatScreen extends StatefulWidget {
  final Conversation conversation;
  final int commissionId;

  const CommissionChatScreen({
    super.key,
    required this.conversation,
    required this.commissionId,
  });

  @override
  State<CommissionChatScreen> createState() => _CommissionChatScreenState();
}

class _CommissionChatScreenState extends State<CommissionChatScreen> {
  final _apiClient = ApiClient();
  final _messageController = TextEditingController();
  Future<List<Message>>? _messagesFuture;
  final ScrollController _scrollController = ScrollController();
  int? _currentUserId;
  late Conversation _conversation;
  bool _commissionMessagingClosed = false;
  bool _commissionStatusLoaded = false;
  String? _commissionTitle;

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
    try {
      final json = await _apiClient.fetchCommission(cid);
      final status = (json['status'] as String?) ?? '';
      final title = (json['title'] as String?)?.trim();
      if (!mounted) return;
      setState(() {
        _commissionMessagingClosed = status == 'completed';
        _commissionStatusLoaded = true;
        _commissionTitle = title != null && title.isNotEmpty ? title : 'Request';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _commissionStatusLoaded = true;
          _commissionTitle ??= 'Request';
        });
      }
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

  String _stageKeyFromRound(int r) {
    if (r <= 1) return 'first';
    if (r == 2) return 'second';
    return 'last';
  }

  Future<void> _openCommissionDetailsFromChat() async {
    final id = widget.commissionId;
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

  Future<void> _onBrushIconPressed() async {
    final id = widget.commissionId;
    try {
      final j = await _apiClient.fetchCommission(id);
      if (!mounted) return;
      final p = Project.fromJson(j);
      if (p.status == ProjectStatus.inProgress) {
        await _openWorkViewFromChat(_stageKeyFromRound(p.submissionRound));
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommissionDetailScreen(commission: p),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open: $e')),
      );
    }
  }

  Widget _buildCommissionHeader() {
    final cid = widget.commissionId;
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black26,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BackButton(color: Colors.black),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.black12,
                          child: Icon(Icons.person,
                              color: Colors.grey.shade700, size: 26),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _chatPeerDisplayName(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF111111),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black87),
                    onSelected: (value) {
                      if (value == 'details') {
                        _openCommissionDetailsFromChat();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'details',
                        child: Text('Commission details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: _kCommissionSubheaderBg,
              child: Row(
                children: [
                  Text(
                    'Commission No#$cid',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF444444),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Expanded(
                    child: Text(
                      _commissionTitle ?? 'Request',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111111),
                          ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 36),
                    icon: const Icon(Icons.brush_outlined,
                        size: 22, color: Color(0xFF444444)),
                    onPressed: _onBrushIconPressed,
                    tooltip: 'Commission work',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return FutureBuilder<List<Message>>(
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
              'No messages in this commission chat yet.',
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == _currentUserId;

            return ChatMessageContent(
              message: message,
              isMe: isMe,
              commissionId: widget.commissionId,
              onViewWorkStage: _openWorkViewFromChat,
            );
          },
        );
      },
    );
  }

  Widget _buildCompletionBanner() {
    return Material(
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Commission #${widget.commissionId} is completed. You can read messages but cannot send new ones.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF1B5E20),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        top: false,
        child: TextField(
          controller: _messageController,
          enabled: _commissionStatusLoaded,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Message…',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF2F2F4),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            suffixIcon: IconButton(
              onPressed: _commissionStatusLoaded ? _sendMessage : null,
              icon: Icon(
                Icons.send_rounded,
                color: _commissionStatusLoaded
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
              ),
            ),
          ),
          onSubmitted: (_) => _sendMessage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildCommissionHeader(),
          if (_commissionMessagingClosed) _buildCompletionBanner(),
          Expanded(child: _buildMessageList()),
          if (!_commissionMessagingClosed) _buildComposer(),
        ],
      ),
    );
  }
}