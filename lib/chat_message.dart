import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/message.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.message,
    required this.isMe,
  });

  final Message message;
  final bool isMe;

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (timestamp.isAfter(today)) {
      return DateFormat('a h:mm', 'ko-KR').format(timestamp);
    } else if (timestamp.isAfter(yesterday)) {
      return DateFormat('어제 a h:mm', 'ko_KR').format(timestamp);
    } else {
      return DateFormat('yyyy년 M월 d일 a h:mm', 'ko_KR').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = _formatTimestamp(message.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[400],
              child: Text(
                message.sender.isNotEmpty ? message.sender[0] : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withAlpha(25), // withOpacity(0.1)
                    blurRadius: 4,
                    offset: const Offset(0, 2),
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
                      const SizedBox(width: 8),
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
                  const SizedBox(height: 4),
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
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
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
