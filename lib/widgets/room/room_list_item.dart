import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_chat_app/models/room.dart';
import 'package:intl/intl.dart'; // DateFormat 사용을 위한 임포트
import 'package:my_chat_app/constants/ui_constants.dart';

class RoomListItem extends StatelessWidget {
  final Room room;
  final VoidCallback onLongPress;

  const RoomListItem({super.key, required this.room, required this.onLongPress});

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (timestamp.isAfter(today)) {
      return DateFormat('a h:mm', 'ko-KR').format(timestamp);
    } else if (timestamp.isAfter(yesterday)) {
      return DateFormat('어제 a h:mm', 'ko-KR').format(timestamp);
    } else {
      return DateFormat('yyyy.MM.dd', 'ko-KR').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: UIConstants.paddingMedium, vertical: UIConstants.spacingSmall),
      child: InkWell(
        onTap: () {
          context.push('/chat/${room.id}');
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusCircular),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.paddingMedium),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (room.lastMessageContent != null)
                      Padding(
                        padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
                        child: Text(
                          room.lastMessageContent!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (room.lastMessageCreatedAt != null)
                    Text(
                      _formatTimestamp(room.lastMessageCreatedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  if (room.unreadCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: UIConstants.paddingSmall,
                            vertical: UIConstants.spacingSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(UIConstants.borderRadiusCircular),
                        ),
                        child: Text(
                          '${room.unreadCount}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
