import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/models/profile.dart';
import 'package:my_chat_app/repositories/profile_repository.dart';
import 'package:my_chat_app/providers/chat_provider.dart'; // ChatProvider 임포트

class ProfileProvider with ChangeNotifier {
  final ProfileRepository _profileRepository;
  final ChatProvider _chatProvider; // ChatProvider 인스턴스 추가
  Profile? _currentProfile;
  bool _isLoading = false;
  String? _error;
  final Map<String, Profile> _profileCache = {}; // 프로필 캐시 추가

  Profile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProfileProvider({
    ProfileRepository? profileRepository,
    required ChatProvider chatProvider,
  }) : _profileRepository =
           profileRepository ?? ProfileRepository(Supabase.instance.client),
       _chatProvider = chatProvider;

  // 특정 사용자 ID로 프로필 가져오기 (캐시 사용)
  Future<Profile?> getProfileById(String userId) async {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId];
    }

    try {
      final profile = await _profileRepository.getProfileById(userId);
      if (profile != null) {
        _profileCache[userId] = profile;
      }
      return profile;
    } catch (e) {
      print('Error fetching profile for $userId: $e'); // 에러 로깅
      return null;
    }
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final userId = _chatProvider.myLocalUserId;
    if (userId == null) {
      _error = '로컬 사용자 ID를 찾을 수 없습니다.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _currentProfile = await _profileRepository.getMyProfile(userId);
    } catch (e) {
      _error = '프로필 로딩에 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? nickname, String? statusMessage}) async {
    final userId = _chatProvider.myLocalUserId;
    if (userId == null) {
      _error = '로컬 사용자 ID를 찾을 수 없습니다. 로그인 상태를 확인해주세요.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newProfile = Profile(
        id: userId,
        nickname: nickname ?? _currentProfile?.nickname ?? '',
        avatarUrl: _currentProfile?.avatarUrl,
        statusMessage: statusMessage ?? _currentProfile?.statusMessage,
      );
      await _profileRepository.upsertProfile(newProfile);
      await loadProfile(); // 업데이트된 프로필 정보를 다시 로드
    } catch (e) {
      _error = '프로필 업데이트에 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadAvatar(XFile imageFile) async {
    final userId = _chatProvider.myLocalUserId;
    if (userId == null) {
      _error = '로컬 사용자 ID를 찾을 수 없습니다. 로그인 상태를 확인해주세요.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final imageUrl = await _profileRepository.uploadAvatar(imageFile, userId);
      final newProfile = Profile(
        id: userId,
        nickname: _currentProfile?.nickname ?? '',
        avatarUrl: imageUrl,
        statusMessage: _currentProfile?.statusMessage,
      );
      await _profileRepository.upsertProfile(newProfile);
      await loadProfile(); // 업데이트된 프로필 정보를 다시 로드
    } catch (e) {
      _error = '아바타 업로드에 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
