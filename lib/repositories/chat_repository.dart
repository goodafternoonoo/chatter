import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../constants/app_constants.dart';

/// 채팅 관련 데이터를 Supabase와 통신하는 리포지토리 클래스입니다.
///
/// 메시지 스트림 구독, 메시지 전송, 이미지 업로드 등의 기능을 담당합니다.
class ChatRepository {
  final SupabaseClient _supabase;

  /// {@template chat_repository}
  /// `ChatRepository`의 인스턴스를 생성합니다.
  ///
  /// [_supabase] Supabase 클라이언트 인스턴스입니다.
  /// {@endtemplate}
  ChatRepository(this._supabase);

  /// 특정 채팅방의 메시지 스트림을 구독합니다.
  ///
  /// [roomId] 메시지를 가져올 채팅방의 ID입니다.
  ///
  /// 최신 메시지가 먼저 오도록 정렬된 `Message` 객체의 리스트 스트림을 반환합니다.
  Stream<List<Message>> getMessagesStream(String roomId) {
    return _supabase
        .from(AppConstants.messagesTableName)
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => Message.fromJson(item)).toList());
  }

  /// 특정 채팅방의 최신 메시지를 가져옵니다.
  ///
  /// [roomId] 메시지를 가져올 채팅방의 ID입니다.
  /// [limit] 가져올 메시지의 최대 개수입니다.
  ///
  /// 최신 메시지 순서로 정렬된 `Message` 객체의 리스트를 반환합니다.
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

  /// 특정 시점 이전의 메시지들을 가져옵니다. (무한 스크롤용)
  ///
  /// [roomId] 메시지를 가져올 채팅방의 ID입니다.
  /// [cursor] 기준이 되는 메시지의 생성 시간입니다. 이 시간보다 오래된 메시지를 가져옵니다.
  /// [limit] 가져올 메시지의 최대 개수입니다.
  ///
  /// 최신 메시지 순서로 정렬된 `Message` 객체의 리스트를 반환합니다.
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

  /// 새로운 메시지를 전송합니다.
  ///
  /// [roomId] 메시지를 보낼 채팅방의 ID입니다.
  /// [content] 메시지의 텍스트 내용입니다.
  /// [localUserId] 메시지를 보내는 사용자의 로컬 ID입니다.
  /// [imageUrl] 메시지에 포함될 이미지의 URL입니다. (옵션)
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

  /// 특정 메시지를 논리적으로 삭제 처리합니다.
  ///
  /// [messageId] 삭제할 메시지의 ID입니다.
  Future<void> markMessageAsDeleted(String messageId) async {
    await _supabase
        .from(AppConstants.messagesTableName)
        .update({'is_deleted': true})
        .eq('id', messageId);
  }

  /// 이미지를 Supabase Storage에 업로드합니다.
  ///
  /// [imageFile] 업로드할 이미지 파일 객체입니다.
  ///
  /// 업로드된 이미지의 공개 URL을 반환합니다.
  Future<String> uploadImage(XFile imageFile) async {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String path = 'chat-images/$fileName';

    await _supabase.storage.from('chat-images').upload(
          path,
          File(imageFile.path),
          fileOptions: const FileOptions(upsert: true),
        );

    final String publicUrl =
        _supabase.storage.from('chat-images').getPublicUrl(path);
    return publicUrl;
  }

  /// 특정 메시지를 읽음 처리합니다.
  ///
  /// Supabase의 `mark_message_as_read` RPC 함수를 호출합니다.
  ///
  /// [messageId] 읽음 처리할 메시지의 ID입니다.
  /// [localUserId] 메시지를 읽은 사용자의 로컬 ID입니다.
  Future<void> markMessageAsRead(String messageId, String? localUserId) async {
    if (localUserId == null) return;
    await _supabase.rpc(
      'mark_message_as_read',
      params: {'message_id': messageId, 'user_id': localUserId},
    );
  }

  /// 채팅방 내에서 메시지를 검색합니다.
  ///
  /// [roomId] 검색을 수행할 채팅방의 ID입니다.
  /// [query] 검색할 키워드입니다.
  ///
  /// 검색어와 일치하는 `Message` 객체의 리스트를 반환합니다.
  Future<List<Message>> searchMessages(
      {required String roomId, required String query}) async {
    final response = await _supabase
        .from(AppConstants.messagesTableName)
        .select()
        .eq('room_id', roomId)
        .eq('is_deleted', false) // 삭제되지 않은 메시지만 검색
        .ilike('content',
            '%$query%') // content 필드에서 검색어 포함 여부 확인 (대소문자 구분 안 함)
        .order('created_at', ascending: false);

    return response.map((item) => Message.fromJson(item)).toList();
  }

  /// 특정 채팅방의 마지막 메시지를 가져옵니다.
  ///
  /// [roomId] 마지막 메시지를 가져올 채팅방의 ID입니다.
  ///
  /// 마지막 `Message` 객체를 반환합니다. 메시지가 없으면 `null`을 반환합니다.
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
