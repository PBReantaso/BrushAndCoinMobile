import 'package:flutter/material.dart';

import '../../../models/app_models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/content_spacing.dart';
import '../../../services/api_client.dart';
import '../../../widgets/communication/chat_message_content.dart';
import 'commission_detail_screen.dart';
import 'commission_work_view_screen.dart';

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

  PreferredSizeWidget _commissionAppBar() {
    return AppBar(
      leading: const BackButton(color: Color(0xFF1F1F24)),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE8E8EC),
            child: Icon(Icons.person, color: const Color(0xFF6E6E6E), size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            _chatPeerDisplayName(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: BcColors.brandRed,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      centerTitle: true,
      toolbarHeight: 90,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF1F1F24)),
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
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: BcColors.cardBorder),
      ),
    );
  }

  Widget _buildCommissionContextStrip() {
    final cid = widget.commissionId;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: BcColors.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: kScreenHorizontalPadding,
        vertical: 10,
      ),
      child: Row(
        children: [
          Text(
            'Commission No#$cid',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF8C8C90),
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
                    color: const Color(0xFF1A1A1E),
                  ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
            icon: const Icon(
              Icons.brush_outlined,
              size: 22,
              color: Color(0xFF1F1F24),
            ),
            onPressed: _onBrushIconPressed,
            tooltip: 'Commission work',
          ),
        ],
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
              'No messages in this commission chat yet.',
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
              commissionId: widget.commissionId,
              onViewWorkStage: _openWorkViewFromChat,
            );
          },
        );
      },
    );
  }

  Widget _buildCompletionBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kScreenHorizontalPadding,
        10,
        kScreenHorizontalPadding,
        8,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BcColors.cardBorder),
        ),
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
                      height: 1.35,
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
                const EdgeInsets.symmetric(
                  horizontal: kScreenHorizontalPadding,
                  vertical: 12,
                ),
            suffixIcon: IconButton(
              onPressed: _commissionStatusLoaded ? _sendMessage : null,
              icon: Icon(
                Icons.send_rounded,
                color: _commissionStatusLoaded
                    ? BcColors.brandRed
                    : const Color(0xFFB0B0B6),
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
      appBar: _commissionAppBar(),
      body: Column(
        children: [
          _buildCommissionContextStrip(),
          if (_commissionMessagingClosed) _buildCompletionBanner(),
          Expanded(child: _buildMessageList()),
          if (!_commissionMessagingClosed) _buildComposer(),
        ],
      ),
    );
  }
}