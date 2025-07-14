import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/screens/chat_page.dart';
import 'package:my_chat_app/models/room.dart'; // Room 모델을 곧 생성할 예정입니다.
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/chat_provider.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final _roomStream = Supabase.instance.client.from('rooms').stream(primaryKey: ['id']).map((maps) => maps.map((map) => Room.fromMap(map)).toList());
  final _newRoomController = TextEditingController();

  Future<void> _createRoom() async {
    final roomName = _newRoomController.text.trim();
    if (roomName.isNotEmpty) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        await Supabase.instance.client.from('rooms').insert({'name': roomName});
        _newRoomController.clear();
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('채팅방 생성에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _deleteRoom(String roomId) async {
    try {
      await Supabase.instance.client.from('rooms').delete().eq('id', roomId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('채팅방이 삭제되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅방 삭제에 실패했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅방 목록'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Room>>(
              stream: _roomStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                }
                final rooms = snapshot.data!;
                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return ListTile(
                      title: Text(room.name),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                              create: (_) => ChatProvider(roomId: room.id)..initialize(),
                              child: ChatPage(roomId: room.id),
                            ),
                          ),
                        );
                      },
                      onLongPress: () {
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
                                      Navigator.pop(context); // 모달 닫기
                                      _deleteRoom(room.id);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newRoomController,
                    decoration: const InputDecoration(
                      hintText: '새 채팅방 이름',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _createRoom,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
