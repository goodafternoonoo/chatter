import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_chat_app/models/profile.dart';

/// 사용자 프로필 관련 데이터를 Supabase와 통신하는 리포지토리 클래스입니다.
///
/// 프로필 조회, 생성, 업데이트, 아바타 업로드 등의 기능을 담당합니다.
class ProfileRepository {
  final SupabaseClient _supabase;

  /// {@template profile_repository}
  /// `ProfileRepository`의 인스턴스를 생성합니다.
  ///
  /// [_supabase] Supabase 클라이언트 인스턴스입니다.
  /// {@endtemplate}
  ProfileRepository(this._supabase);

  /// 주어진 ID를 가진 사용자의 프로필을 가져옵니다.
  ///
  /// [userId] 가져올 프로필의 사용자 ID입니다.
  ///
  /// `Profile` 객체를 반환합니다. 해당 사용자가 없으면 `null`을 반환합니다.
  Future<Profile?> getMyProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('id, nickname, avatar_url, status_message, last_seen, is_online')
        .eq('id', userId)
        .maybeSingle(); // single() 대신 maybeSingle() 사용

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  /// 프로필 정보를 생성하거나 업데이트합니다. (Upsert)
  ///
  /// [profile] 생성 또는 업데이트할 `Profile` 객체입니다.
  Future<void> upsertProfile(Profile profile) async {
    await _supabase.from('profiles').upsert(profile.toJson());
  }

  /// 사용자의 접속 상태(온라인/오프라인)를 업데이트합니다.
  ///
  /// [userId] 상태를 업데이트할 사용자의 ID입니다.
  /// [isOnline] 온라인 상태 여부입니다.
  /// [lastSeen] 마지막 접속 시간입니다. `null`이면 현재 시간으로 설정됩니다.
  Future<void> updateUserPresence({
    required String userId,
    required bool isOnline,
    DateTime? lastSeen,
  }) async {
    await _supabase.from('profiles').update({
      'is_online': isOnline,
      'last_seen':
          lastSeen?.toIso8601String() ?? DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// 사용자 아바타 이미지를 Supabase Storage에 업로드합니다.
  ///
  /// [imageFile] 업로드할 이미지 파일입니다.
  /// [userId] 이미지를 업로드하는 사용자의 ID입니다.
  ///
  /// 업로드된 이미지의 공개 URL을 반환합니다.
  Future<String> uploadAvatar(XFile imageFile, String userId) async {
    final String fileName =
        '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String path = 'avatars/$fileName';

    await _supabase.storage.from('avatars').upload(
          path,
          File(imageFile.path),
          fileOptions: const FileOptions(upsert: true),
        );

    final String publicUrl =
        _supabase.storage.from('avatars').getPublicUrl(path);
    return publicUrl;
  }

  /// 주어진 ID를 가진 사용자의 프로필을 한 번 가져옵니다.
  /// `getMyProfile`과 기능적으로 동일하지만, 다른 컨텍스트에서 사용될 수 있습니다.
  ///
  /// [userId] 가져올 프로필의 사용자 ID입니다.
  ///
  /// `Profile` 객체를 반환합니다. 해당 사용자가 없으면 `null`을 반환합니다.
  Future<Profile?> getProfileById(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('id, nickname, avatar_url, status_message, last_seen, is_online')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  /// 특정 사용자 프로필의 변경 사항을 실시간으로 구독합니다.
  ///
  /// [userId] 구독할 프로필의 사용자 ID입니다.
  ///
  /// `Profile` 객체의 스트림을 반환합니다. 프로필이 변경될 때마다 새로운 `Profile` 객체가 스트림으로 전달됩니다.
  Stream<Profile> getProfileStreamById(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .limit(1)
        .map((data) => Profile.fromJson(data.first));
  }
}
