import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/room_provider.dart';
import 'package:my_chat_app/utils/toast_utils.dart';
import 'package:my_chat_app/widgets/room/room_list_item.dart';
import 'package:my_chat_app/widgets/room/create_room_bottom_sheet.dart';
import 'package:my_chat_app/widgets/common_app_bar.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final _newRoomController = TextEditingController();

  Future<void> _createRoom() async {
    final roomName = _newRoomController.text.trim();
    if (roomName.isNotEmpty) {
      try {
        await context.read<RoomProvider>().createRoom(roomName);
        _newRoomController.clear();
      } catch (e) {
        if (!mounted) return;
        ToastUtils.showToast(context, '채팅방 생성에 실패했습니다: $e');
      }
    }
  }

  Future<void> _deleteRoom(String roomId) async {
    try {
      await context.read<RoomProvider>().deleteRoom(roomId);
      if (!mounted) return;
      ToastUtils.showToast(context, '채팅방이 삭제되었습니다.');
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showToast(context, '채팅방 삭제에 실패했습니다: $e');
    }
  }

  Future<void> _showCreateRoomBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return CreateRoomBottomSheet(
          controller: _newRoomController,
          onCreate: _createRoom,
        );
      },
    );
  }

  void _showDeleteRoomBottomSheet(String roomId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('채팅방 삭제'),
                onTap: () {
                  context.pop();
                  _deleteRoom(roomId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: const Text('채팅방 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: '프로필 관리',
            onPressed: () {
              context.push('/profile');
            },
          ),
        ],
      ),
      body: Consumer<RoomProvider>(
        builder: (context, roomProvider, child) {
          if (roomProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (roomProvider.error != null) {
            return Center(child: Text('오류가 발생했습니다: ${roomProvider.error}'));
          }
          final rooms = roomProvider.rooms;
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return RoomListItem(
                room: room,
                onLongPress: () => _showDeleteRoomBottomSheet(room.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoomBottomSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}