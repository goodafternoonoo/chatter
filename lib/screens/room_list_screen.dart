import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/room_provider.dart';
import 'package:my_chat_app/utils/toast_utils.dart';
import 'package:my_chat_app/widgets/room/room_list_item.dart';
import 'package:my_chat_app/widgets/room/create_room_bottom_sheet.dart';
import 'package:my_chat_app/widgets/common_app_bar.dart';

/// 채팅방 목록을 표시하는 화면입니다.
///
/// `RoomProvider`를 통해 실시간으로 채팅방 목록을 가져와 `RoomListItem`으로 표시합니다.
/// 사용자는 플로팅 액션 버튼을 통해 새로운 채팅방을 생성할 수 있으며,
/// 각 채팅방을 길게 눌러 삭제할 수 있습니다.
class RoomListScreen extends StatefulWidget {
  /// {@template room_list_screen}
  /// `RoomListScreen` 위젯을 생성합니다.
  /// {@endtemplate}
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final _newRoomController = TextEditingController();

  @override
  void dispose() {
    _newRoomController.dispose();
    super.dispose();
  }

  /// `RoomProvider`를 호출하여 새로운 채팅방을 생성합니다.
  Future<void> _createRoom() async {
    final roomName = _newRoomController.text.trim();
    if (roomName.isNotEmpty) {
      try {
        await context.read<RoomProvider>().createRoom(roomName);
        _newRoomController.clear();
      } catch (e) {
        if (mounted) {
          ToastUtils.showToast(context, '채팅방 생성에 실패했습니다: $e');
        }
      }
    }
  }

  /// `RoomProvider`를 호출하여 특정 채팅방을 삭제합니다.
  ///
  /// [roomId] 삭제할 채팅방의 ID입니다.
  Future<void> _deleteRoom(String roomId) async {
    try {
      await context.read<RoomProvider>().deleteRoom(roomId);
      if (mounted) {
        ToastUtils.showToast(context, '채팅방이 삭제되었습니다.');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showToast(context, '채팅방 삭제에 실패했습니다: $e');
      }
    }
  }

  /// 채팅방 생성을 위한 바텀 시트를 표시합니다.
  Future<void> _showCreateRoomBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 키보드가 올라올 때 UI가 가려지지 않도록 설정
      builder: (BuildContext bc) {
        return CreateRoomBottomSheet(
          controller: _newRoomController,
          onCreate: _createRoom,
        );
      },
    );
  }

  /// 채팅방 삭제 확인을 위한 바텀 시트를 표시합니다.
  ///
  /// [roomId] 삭제할 채팅방의 ID입니다.
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
                  context.pop(); // 바텀 시트 닫기
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
      appBar: null, // 기본 AppBar 제거
      body: Column(
        children: [
          const CommonAppBar(
            title: Text('채팅방 목록'),
            automaticallyImplyLeading: false, // 이 화면에서는 뒤로가기 버튼 불필요
          ),
          Expanded(
            child: Consumer<RoomProvider>(
              builder: (context, roomProvider, child) {
                if (roomProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (roomProvider.error != null) {
                  return Center(
                    child: Text('오류가 발생했습니다: ${roomProvider.error}'),
                  );
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoomBottomSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}
