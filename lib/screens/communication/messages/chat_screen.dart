import 'package:flutter/material.dart';

import '../../../models/app_models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/content_spacing.dart';
import '../../../services/api_client.dart';
import '../../../widgets/communication/chat_message_content.dart';
import '../commissions/commission_work_view_screen.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({
    super.key,
    required this.conversation,
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

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _loadCurrentUserId();
    _messagesFuture = _loadMessages();
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

  Future<void> _openWorkViewFromChat(String stageKey) async {
    final id = _conversation.commissionId;
    if (id == null) return;
    try {
      final j = await _apiClient.fetchCommission(id);
      if (!mounted) return;
      final p = Project.fromJson(j);
      final patronReview = _currentUserId != null &&
          p.patronId == _currentUserId &&
          p.status == ProjectStatus.inProgress;
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CommissionWorkViewScreen(
            commission: p,
            workStageKey: stageKey,
            patronReviewMode: patronReview,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open work: $e')),
      );
    }
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
              style: FilledButton.styleFrom(
                backgroundColor: BcColors.brandRed,
                foregroundColor: Colors.white,
              ),
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
                    color: const Color(0xFF6E6E6E),
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

        final cid = _conversation.commissionId;

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: kScreenHorizontalPadding,
            vertical: 12,
          ),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == _currentUserId;

            return ChatMessageContent(
              message: message,
              isMe: isMe,
              commissionId: cid,
              onViewWorkStage: cid != null ? _openWorkViewFromChat : null,
            );
          },
        );
      },
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        kScreenHorizontalPadding,
        10,
        kScreenHorizontalPadding,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: BcColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: TextField(
          controller: _messageController,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Type a message…',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF2F2F4),
            contentPadding:
                const EdgeInsets.symmetric(
                  horizontal: kScreenHorizontalPadding,
                  vertical: 12,
                ),
            suffixIcon: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send_rounded,
                color: kChatOutgoingRed,
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
      backgroundColor: BcColors.pageBackground,
      appBar: AppBar(
        leading: const BackButton(color: Color(0xFF1F1F24)),
        title: Text(
          _conversation.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: BcColors.brandRed,
              ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F1F24),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: BcColors.cardBorder),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildComposer(),
        ],
      ),
    );
  }
}
