import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_chat_app/models/room.dart';

class RoomListItem extends StatelessWidget {
  final Room room;
  final VoidCallback onLongPress;

  const RoomListItem({super.key, required this.room, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(room.name),
      trailing: room.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${room.unreadCount}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
            )
          : null,
      onTap: () {
        context.push('/chat/${room.id}');
      },
      onLongPress: onLongPress,
    );
  }
}
