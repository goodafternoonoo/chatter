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
      onTap: () {
        context.push('/chat/${room.id}');
      },
      onLongPress: onLongPress,
    );
  }
}
