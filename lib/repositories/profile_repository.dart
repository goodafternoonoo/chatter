import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_chat_app/models/profile.dart'; // Profile 모델 임포트 예정

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  // 현재 사용자 프로필 가져오기
  Future<Profile?> getMyProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('id, nickname, avatar_url, status_message, last_seen, is_online')
        .eq('id', userId)
        .maybeSingle(); // single() 대신 maybeSingle() 사용

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  // 프로필 삽입 또는 업데이트 (upsert)
  Future<void> upsertProfile(Profile profile) async {
    await _supabase.from('profiles').upsert(profile.toJson());
  }

  // 사용자 온라인 상태 업데이트
  Future<void> updateUserPresence({
    required String userId,
    required bool isOnline,
    DateTime? lastSeen,
  }) async {
    await _supabase.from('profiles').update({
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String() ?? DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // 아바타 이미지 업로드
  Future<String> uploadAvatar(XFile imageFile, String userId) async {
    final String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String path = 'avatars/$fileName';

    await _supabase.storage
        .from('avatars') // 'avatars' 버킷 사용
        .upload(
          path,
          File(imageFile.path),
          fileOptions: const FileOptions(upsert: true),
        );

    final String publicUrl = _supabase.storage
        .from('avatars')
        .getPublicUrl(path);
    return publicUrl;
  }

  // 특정 사용자 프로필 가져오기
  Future<Profile?> getProfileById(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('id, nickname, avatar_url, status_message, last_seen, is_online')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  // 특정 사용자 프로필 변경 스트림 가져오기
  Stream<Profile> getProfileStreamById(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .limit(1)
        .map((data) => Profile.fromJson(data.first));
  }
}
