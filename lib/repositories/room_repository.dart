import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/models/room.dart';

class RoomRepository {
  final SupabaseClient _client;

  RoomRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Stream<List<Room>> getRoomStream() {
    return _client
        .from('rooms')
        .stream(primaryKey: ['id']).map((maps) => maps.map((map) => Room.fromMap(map)).toList());
  }

  Future<void> createRoom(String name) async {
    await _client.from('rooms').insert({'name': name});
  }

  Future<void> deleteRoom(String roomId) async {
    await _client.from('rooms').delete().eq('id', roomId);
  }
}
