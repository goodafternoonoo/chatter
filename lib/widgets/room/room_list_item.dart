import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_chat_app/models/room.dart';
import 'package:intl/intl.dart'; // DateFormat 사용을 위한 임포트

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
    return ListTile(
      title: Text(room.name),
      subtitle: room.lastMessageContent != null
          ? Text(
              room.lastMessageContent!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (room.lastMessageCreatedAt != null)
            Text(
              _formatTimestamp(room.lastMessageCreatedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (room.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${room.unreadCount}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
            ),
        ],
      ),
      onTap: () {
        context.push('/chat/${room.id}');
      },
      onLongPress: onLongPress,
    );
  }
}
