import 'dart:developer'; // dart:developer 임포트
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/models/profile.dart';
import 'package:my_chat_app/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 임포트
import 'package:uuid/uuid.dart'; // Uuid 임포트

class ProfileProvider with ChangeNotifier, WidgetsBindingObserver {
  final ProfileRepository _profileRepository;
  Profile? _currentProfile;
  bool _isLoading = false;
  String? _error;
  final Map<String, Profile> _profileCache = {}; // 프로필 캐시 추가
  String? _localUserId; // 로컬 사용자 ID 필드 추가
  String _currentNickname = '알 수 없음'; // 현재 닉네임 필드 추가

  Profile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentLocalUserId => _localUserId; // 로컬 사용자 ID getter 추가
  String get currentNickname => _currentNickname; // 현재 닉네임 getter 추가

  ProfileProvider({
    ProfileRepository? profileRepository,
  }) : _profileRepository =
           profileRepository ?? ProfileRepository(Supabase.instance.client) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_localUserId == null) return; // 사용자 ID가 없으면 처리하지 않음

    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아올 때 온라인 상태로 설정
      updateUserPresence(isOnline: true);
    } else if (state == AppLifecycleState.paused) {
      // 앱이 백그라운드로 갈 때 오프라인 상태로 설정하고 마지막 활동 시간 기록
      updateUserPresence(isOnline: false, lastSeen: DateTime.now());
    }
  }

  Future<void> initialize() async {
    _localUserId = await _loadLocalUserId();
    _currentNickname = await _loadNickname() ?? '알 수 없음';
    await loadProfile();
  }

  Future<String?> _loadLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? localUserId = prefs.getString('local_user_id');
    if (localUserId == null) {
      localUserId = const Uuid().v4();
      await prefs.setString('local_user_id', localUserId);
    }
    return localUserId;
  }

  Future<String?> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nickname');
  }

  Future<void> saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', nickname);
    _currentNickname = nickname;
    notifyListeners();
  }

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
      log('Error fetching profile for $userId', name: 'ProfileProvider', error: e); // 에러 로깅
      return null;
    }
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final userId = _localUserId;
    if (userId == null) {
      _error = '로컬 사용자 ID를 찾을 수 없습니다.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _currentProfile = await _profileRepository.getMyProfile(userId);
      // 프로필 로드 후 온라인 상태로 설정
      await _profileRepository.updateUserPresence(userId: userId, isOnline: true);
    } catch (e) {
      _error = '프로필 로딩에 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? nickname, String? statusMessage}) async {
    final userId = _localUserId;
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
        lastSeen: _currentProfile?.lastSeen,
        isOnline: _currentProfile?.isOnline ?? false,
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
    final userId = _localUserId;
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
        lastSeen: _currentProfile?.lastSeen,
        isOnline: _currentProfile?.isOnline ?? false,
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

  // 사용자 온라인 상태 업데이트 (내부용)
  Future<void> updateUserPresence({required bool isOnline, DateTime? lastSeen}) async {
    if (_localUserId == null) return;
    try {
      await _profileRepository.updateUserPresence(
        userId: _localUserId!,
        isOnline: isOnline,
        lastSeen: lastSeen,
      );
      // 로컬 캐시 업데이트
      _currentProfile = _currentProfile?.copyWith(isOnline: isOnline, lastSeen: lastSeen ?? DateTime.now());
      notifyListeners();
    } catch (e) {
      log('Error updating user presence', name: 'ProfileProvider', error: e);
    }
  }
}