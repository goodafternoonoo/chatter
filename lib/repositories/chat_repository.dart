import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
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
    required String content,
    required String localUserId,
    String? imageUrl,
  }) async {
    await _supabase.from(AppConstants.messagesTableName).insert({
      'room_id': roomId,
      'content': content,
      'local_user_id': localUserId,
      'image_url': imageUrl,
    });
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

  Future<void> markMessageAsRead(String messageId, String localUserId) async {
    final List<dynamic> response = await _supabase
        .from(AppConstants.messagesTableName)
        .select('read_by')
        .eq('id', messageId)
        .limit(1);

    if (response.isEmpty) return;

    final currentReadBy = (response[0]['read_by'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    if (currentReadBy.contains(localUserId)) {
      return;
    }

    final newReadBy = List<String>.from(currentReadBy);
    newReadBy.add(localUserId);

    await _supabase
        .from(AppConstants.messagesTableName)
        .update({'read_by': newReadBy})
        .eq('id', messageId);
  }

  // SharedPreferences 관련 로직은 ChatProvider에 유지합니다.
  // 이는 로컬 저장소에 대한 책임이 ChatProvider에 더 가깝기 때문입니다.
  Future<String?> loadLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? localUserId = prefs.getString('local_user_id');
    if (localUserId == null) {
      localUserId = const Uuid().v4();
      await prefs.setString('local_user_id', localUserId);
    }
    return localUserId;
  }

  Future<String?> loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nickname');
  }

  Future<void> saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', nickname);
  }
}
