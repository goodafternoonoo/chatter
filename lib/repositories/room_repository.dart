import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/models/room.dart';

/// 채팅방 관련 데이터를 Supabase와 통신하는 리포지토리 클래스입니다.
///
/// 채팅방 목록 조회, 생성, 삭제 기능을 담당합니다.
class RoomRepository {
  final SupabaseClient _client;

  /// {@template room_repository}
  /// `RoomRepository`의 인스턴스를 생성합니다.
  ///
  /// [client] Supabase 클라이언트 인스턴스입니다. 제공되지 않으면 `Supabase.instance.client`를 사용합니다.
  /// {@endtemplate}
  RoomRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// 모든 채팅방 목록의 변경 사항을 실시간으로 구독합니다.
  ///
  /// `Room` 객체 리스트의 스트림을 반환합니다. 채팅방이 추가, 수정, 삭제될 때마다
  /// 새로운 리스트가 스트림으로 전달됩니다.
  Stream<List<Room>> getRoomStream() {
    return _client.from('rooms').stream(primaryKey: [
      'id'
    ]).map((maps) => maps.map((map) => Room.fromMap(map)).toList());
  }

  /// 새로운 채팅방을 생성합니다.
  ///
  /// [name] 생성할 채팅방의 이름입니다.
  Future<void> createRoom(String name) async {
    await _client.from('rooms').insert({'name': name});
  }

  /// 특정 채팅방을 삭제합니다.
  ///
  /// [roomId] 삭제할 채팅방의 ID입니다.
  Future<void> deleteRoom(String roomId) async {
    await _client.from('rooms').delete().eq('id', roomId);
  }
}
