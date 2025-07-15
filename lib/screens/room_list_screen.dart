import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart'; // go_router 임포트
import 'package:my_chat_app/models/room.dart';

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

  Future<void> _showCreateRoomBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bc).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _newRoomController,
                decoration: const InputDecoration(
                  hintText: '새 채팅방 이름',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (value) {
                  _createRoom();
                  context.pop(); // 모달 닫기
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _createRoom();
                  context.pop(); // 모달 닫기
                },
                child: const Text('채팅방 생성'),
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
      appBar: AppBar(
        title: const Text('채팅방 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: '닉네임 수정',
            onPressed: () {
              context.go('/nickname');
            },
          ),
        ],
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
                        context.push('/chat/${room.id}');
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
                                      context.pop(); // 모달 닫기
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoomBottomSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}