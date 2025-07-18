import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../constants/app_constants.dart';

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  Stream<List<Message>> getMessagesStream(String roomId) {
    return _supabase
        .from(AppConstants.messagesTableName)
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => Message.fromJson(item)).toList());
  }

  Future<List<Message>> fetchLatestMessages({
    required String roomId,
    int limit = 20,
  }) async {
    final response = await _supabase
        .from(AppConstants.messagesTableName)
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: false) // 최신순으로 정렬
        .limit(limit);

    return response.map((item) => Message.fromJson(item)).toList();
  }

  Future<List<Message>> fetchPreviousMessages({
    required String roomId,
    required DateTime cursor,
    int limit = 20,
  }) async {
    final response = await _supabase
        .from(AppConstants.messagesTableName)
        .select()
        .eq('room_id', roomId)
        // .lt()에서 .lte()로 변경하여 동일 시간의 메시지를 포함시키고,
        // .toUtc()를 호출하여 Dart의 DateTime을 DB의 TIMESTAMPTZ와 일치하는
        // UTC 시간으로 변환합니다. 이것이 Timezone 문제의 핵심 해결책입니다.
        .lte('created_at', cursor.toUtc().toIso8601String())
        .order('created_at', ascending: false) // 최신 순으로 정렬
        .limit(limit);

    return response.map((item) => Message.fromJson(item)).toList();
  }

  Future<void> sendMessage({
    required String roomId,
    required String? content,
    required String? localUserId,
    String? imageUrl,
  }) async {
    await _supabase.from(AppConstants.messagesTableName).insert({
      'room_id': roomId,
      'content': content,
      'local_user_id': localUserId,
      'image_url': imageUrl,
      'is_deleted': false, // 메시지 전송 시 is_deleted 기본값 설정
    });
  }

  Future<void> markMessageAsDeleted(String messageId) async {
    await _supabase
        .from(AppConstants.messagesTableName)
        .update({'is_deleted': true})
        .eq('id', messageId);
  }

  Future<String> uploadImage(XFile imageFile) async {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String path = 'chat-images/$fileName';

    await _supabase.storage
        .from('chat-images')
        .upload(
          path,
          File(imageFile.path),
          fileOptions: const FileOptions(upsert: true),
        );

    final String publicUrl = _supabase.storage
        .from('chat-images')
        .getPublicUrl(path);
    return publicUrl;
  }

  Future<void> markMessageAsRead(String messageId, String? localUserId) async {
    if (localUserId == null) return;
    await _supabase.rpc(
      'mark_message_as_read',
      params: {'message_id': messageId, 'user_id': localUserId},
    );
  }

  // 메시지 검색
  Future<List<Message>> searchMessages({required String roomId, required String query}) async {
    final response = await _supabase
        .from(AppConstants.messagesTableName)
        .select()
        .eq('room_id', roomId)
        .eq('is_deleted', false) // 삭제되지 않은 메시지만 검색
        .ilike('content', '%$query%') // content 필드에서 검색어 포함 여부 확인 (대소문자 구분 안 함)
        .order('created_at', ascending: false);

    return response.map((item) => Message.fromJson(item)).toList();
  }

  // 특정 방의 마지막 메시지 가져오기
  Future<Message?> fetchLastMessageForRoom(String roomId) async {
    final response = await _supabase
        .from(AppConstants.messagesTableName)
        .select('content, created_at, image_url, is_deleted')
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    // Message 객체로 변환 시 필요한 모든 필드를 포함하도록 수정
    // 여기서는 content, created_at, image_url, is_deleted만 가져오므로
    // Message.fromJson 대신 필요한 필드만 사용하여 Message 객체를 생성합니다.
    return Message(
      id: '', // ID는 필요 없으므로 빈 문자열
      content: response['content'] as String? ?? '',
      localUserId: '', // localUserId는 필요 없으므로 빈 문자열
      createdAt: DateTime.parse(response['created_at'] as String).toLocal(),
      readBy: [], // readBy는 필요 없으므로 빈 리스트
      imageUrl: response['image_url'] as String?,
      isDeleted: response['is_deleted'] as bool? ?? false,
    );
  }
}
