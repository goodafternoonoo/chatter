import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/message.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.message,
    required this.isMe,
    required this.myLocalUserId, // myLocalUserId 추가
  });

  final Message message;
  final bool isMe;
  final String myLocalUserId; // myLocalUserId 필드 추가

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (timestamp.isAfter(today)) {
      return DateFormat('a h:mm', 'ko-KR').format(timestamp);
    } else if (timestamp.isAfter(yesterday)) {
      return DateFormat('어제 a h:mm', 'ko-KR').format(timestamp);
    } else {
      return DateFormat('yyyy년 M월 d일 a h:mm', 'ko-KR').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = _formatTimestamp(message.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.spacingSmall, horizontal: UIConstants.spacingMedium),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: UIConstants.avatarRadius,
              backgroundColor: Colors.grey[400],
              child: Text(
                message.sender.isNotEmpty ? message.sender[0] : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: UIConstants.spacingMedium),
          ],
          if (isMe) // 내가 보낸 메시지일 때만 읽음/안읽음 표시
            Padding(
              padding: const EdgeInsets.only(right: UIConstants.spacingSmall, bottom: UIConstants.spacingSmall / 2), // 말풍선과의 간격 및 하단 정렬
              child: Text(
                message.readBy.any((id) => id != myLocalUserId) ? '읽음' : '1', // 읽음/안읽음 표시
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.primary, // 눈에 띄는 색상으로 변경
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: UIConstants.chatBubbleVerticalPadding, horizontal: UIConstants.chatBubbleHorizontalPadding),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(UIConstants.borderRadiusChatBubble),
                  topRight: const Radius.circular(UIConstants.borderRadiusChatBubble),
                  bottomLeft: isMe ? const Radius.circular(UIConstants.borderRadiusChatBubble) : const Radius.circular(UIConstants.borderRadiusChatBubbleSmall),
                  bottomRight: isMe ? const Radius.circular(UIConstants.borderRadiusChatBubbleSmall) : const Radius.circular(UIConstants.borderRadiusChatBubble),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withAlpha(25), // withOpacity(0.1)
                    blurRadius: UIConstants.spacingSmall,
                    offset: const Offset(0, UIConstants.spacingSmall / 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.sender,
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(
                              color: isMe
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(width: UIConstants.spacingMedium),
                      Text(
                        createdAt,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: isMe
                                  ? Theme.of(context).colorScheme.onPrimaryContainer.withAlpha(178) // withOpacity(0.7)
                                  : Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(178), // withOpacity(0.7)
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: UIConstants.spacingSmall),
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: isMe
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: UIConstants.spacingMedium),
            CircleAvatar(
              radius: UIConstants.avatarRadius,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                message.sender.isNotEmpty ? message.sender[0] : '?',
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
