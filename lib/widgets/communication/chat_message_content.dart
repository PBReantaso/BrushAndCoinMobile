import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../theme/app_colors.dart';

/// Brand red for outgoing bubbles (matches Communication / commission chat).
const Color kChatOutgoingRed = BcColors.brandRed;
const Color kChatIncomingGrey = Color(0xFFEDEDED);

(String artist, String patron)? parseCommissionAccepted(String content) {
  final t = content.trim();
  if (!t.startsWith('COMMISSION_ACCEPTED|')) return null;
  final parts = t.split('|');
  if (parts.length < 3) return null;
  return (parts[1], parts.sublist(2).join('|'));
}

(String stageKey, String artistName)? parseWorkSubmitted(String content) {
  final t = content.trim();
  if (!t.startsWith('WORK_SUBMITTED|')) return null;
  final parts = t.split('|');
  if (parts.length < 3) return null;
  return (parts[1], parts.sublist(2).join('|'));
}

bool isCommissionCompletionSystemLine(String content) {
  final t = content.trim();
  return t.startsWith('Commission No#') && t.toLowerCase().contains('completed');
}

String atHandle(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '@…';
  return t.startsWith('@') ? t : '@$t';
}

/// Renders one message: system commission lines as cards, user text as DM bubbles.
class ChatMessageContent extends StatelessWidget {
  final Message message;
  final bool isMe;
  final int? commissionId;
  /// When set with [commissionId], "View Work" opens the commission work viewer.
  final void Function(String stageKey)? onViewWorkStage;

  const ChatMessageContent({
    super.key,
    required this.message,
    required this.isMe,
    this.commissionId,
    this.onViewWorkStage,
  });

  @override
  Widget build(BuildContext context) {
    final accepted = parseCommissionAccepted(message.content);
    if (accepted != null) {
      return AcceptNoticeBanner(
        artistHandle: atHandle(accepted.$1),
        patronHandle: atHandle(accepted.$2),
      );
    }

    final ws = parseWorkSubmitted(message.content);
    if (ws != null) {
      final showLink = commissionId != null && onViewWorkStage != null;
      return WorkSubmittedNotice(
        stageKey: ws.$1,
        artistName: ws.$2,
        showViewWork: showLink,
        onViewWork: showLink ? () => onViewWorkStage!(ws.$1) : null,
      );
    }

    if (isCommissionCompletionSystemLine(message.content)) {
      return CompletionSystemNotice(text: message.content);
    }

    return ChatDmBubble(
      message: message,
      isMe: isMe,
    );
  }
}

class AcceptNoticeBanner extends StatelessWidget {
  final String artistHandle;
  final String patronHandle;

  const AcceptNoticeBanner({
    super.key,
    required this.artistHandle,
    required this.patronHandle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE6E6EA)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$artistHandle have accepted $patronHandle\'s request.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF333333),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
        ),
      ),
    );
  }
}

class WorkSubmittedNotice extends StatelessWidget {
  final String stageKey;
  final String artistName;
  final bool showViewWork;
  final VoidCallback? onViewWork;

  const WorkSubmittedNotice({
    super.key,
    required this.stageKey,
    required this.artistName,
    this.showViewWork = false,
    this.onViewWork,
  });

  static String stageLabel(String key) {
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
      color: kChatOutgoingRed,
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Column(
          children: [
            Row(children: [
              Expanded(child: Divider(color: const Color(0xFFE6E6EA))),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '$handle have submitted ${stageLabel(stageKey)}. ',
                    textAlign: TextAlign.center,
                    style: baseStyle,
                  ),
                  if (showViewWork && onViewWork != null)
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

class CompletionSystemNotice extends StatelessWidget {
  final String text;

  const CompletionSystemNotice({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F6),
            border: Border.all(color: const Color(0xFFE6E6EA)),
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

class ChatDmBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ChatDmBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? kChatOutgoingRed : kChatIncomingGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isMe ? Colors.white : const Color(0xFF111111),
                fontWeight: FontWeight.w400,
              ),
        ),
      ),
    );
  }
}
