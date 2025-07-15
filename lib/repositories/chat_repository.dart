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
        .order('created_at', ascending: true)
        .map((data) => data.map((item) => Message.fromJson(item)).toList());
  }

  Future<void> sendMessage({
    required String roomId,
    required String content,
    required String sender,
    required String localUserId,
    String? imageUrl,
  }) async {
    await _supabase.from(AppConstants.messagesTableName).insert({
      'room_id': roomId,
      'content': content,
      'sender': sender,
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
