import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/models/profile.dart';
import 'package:my_chat_app/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 사용자 프로필 상태를 관리하는 클래스입니다.
///
/// 현재 사용자의 프로필 로드, 업데이트, 아바타 업로드, 접속 상태 관리 등을 담당합니다.
/// 또한 다른 사용자들의 프로필을 캐싱하고 실시간으로 업데이트하여 API 호출을 최적화합니다.
class ProfileProvider with ChangeNotifier, WidgetsBindingObserver {
  /// 프로필 관련 데이터 통신을 담당하는 리포지토리입니다.
  final ProfileRepository _profileRepository;

  /// 현재 앱을 사용하는 로컬 사용자의 프로필 정보입니다.
  Profile? _currentProfile;

  /// 데이터 로딩 중인지 여부를 나타냅니다.
  bool _isLoading = false;

  /// 발생한 오류 메시지를 저장합니다.
  String? _error;

  /// 다른 사용자들의 프로필 정보를 저장하는 캐시입니다.
  ///
  /// `userId`를 키로 사용하여 프로필 정보를 저장함으로써 중복 API 호출을 방지합니다.
  final Map<String, Profile> _profileCache = {};

  /// 다른 사용자 프로필의 실시간 변경 사항을 구독하는 스트림 구독 관리 맵입니다.
  final Map<String, StreamSubscription<Profile>> _profileSubscriptions = {};

  /// `SharedPreferences`에 저장된 로컬 사용자의 고유 ID입니다.
  String? _localUserId;

  /// `SharedPreferences`에 저장된 로컬 사용자의 닉네임입니다.
  String _currentNickname = '알 수 없음';

  /// 현재 사용자의 프로필을 반환합니다.
  Profile? get currentProfile => _currentProfile;

  /// 현재 로딩 상태를 반환합니다.
  bool get isLoading => _isLoading;

  /// 마지막 오류 메시지를 반환합니다.
  String? get error => _error;

  /// 현재 로컬 사용자의 ID를 반환합니다.
  String? get currentLocalUserId => _localUserId;

  /// 현재 로컬 사용자의 닉네임을 반환합니다.
  String get currentNickname => _currentNickname;

  /// {@template profile_provider}
  /// `ProfileProvider`의 인스턴스를 생성합니다.
  ///
  /// 앱의 생명주기 이벤트를 감지하기 위해 `WidgetsBindingObserver`를 등록합니다.
  /// {@endtemplate}
  ProfileProvider({
    ProfileRepository? profileRepository,
  }) : _profileRepository =
            profileRepository ?? ProfileRepository(Supabase.instance.client) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 모든 활성 스트림 구독을 취소합니다.
    for (var subscription in _profileSubscriptions.values) {
      subscription.cancel();
    }
    _profileSubscriptions.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_localUserId == null) return;

    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아오면 온라인 상태로 업데이트합니다.
      updateUserPresence(isOnline: true);
    } else if (state == AppLifecycleState.paused) {
      // 앱이 백그라운드로 전환되면 오프라인 상태와 마지막 접속 시간을 업데이트합니다.
      updateUserPresence(isOnline: false, lastSeen: DateTime.now());
    }
  }

  /// Provider를 초기화합니다.
  ///
  /// 로컬 저장소에서 사용자 ID와 닉네임을 불러온 후, 전체 프로필 정보를 서버에서 로드합니다.
  Future<void> initialize() async {
    _localUserId = await _loadLocalUserId();
    _currentNickname = await _loadNickname() ?? '알 수 없음';
    await loadProfile();
  }

  /// `SharedPreferences`에서 로컬 사용자 ID를 불러옵니다.
  ///
  /// 저장된 ID가 없으면 새로운 UUID를 생성하여 저장하고 반환합니다.
  Future<String?> _loadLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? localUserId = prefs.getString('local_user_id');
    if (localUserId == null) {
      localUserId = const Uuid().v4();
      await prefs.setString('local_user_id', localUserId);
    }
    return localUserId;
  }

  /// `SharedPreferences`에서 닉네임을 불러옵니다.
  Future<String?> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nickname');
  }

  /// 닉네임을 `SharedPreferences`에 저장하고 로컬 상태를 업데이트합니다.
  ///
  /// [nickname] 저장할 새 닉네임입니다.
  Future<void> saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', nickname);
    _currentNickname = nickname;
    notifyListeners();
  }

  /// 특정 ID를 가진 사용자의 프로필을 가져옵니다.
  ///
  /// 캐싱 및 실시간 스트림 구독을 통해 효율적으로 프로필을 관리합니다.
  /// 1. 캐시에 프로필이 있는지 확인하고 있으면 즉시 반환합니다.
  /// 2. 캐시에 없으면 서버에서 한 번 가져와 캐시에 저장합니다.
  /// 3. 해당 사용자의 프로필 스트림을 아직 구독하지 않았다면, 새로 구독하여 변경 사항을 실시간으로 캐시에 반영합니다.
  ///
  /// [userId] 가져올 프로필의 사용자 ID입니다.
  ///
  /// `Profile` 객체를 반환하며, 오류 발생 시 `null`을 반환할 수 있습니다.
  Future<Profile?> getProfileById(String userId) async {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId];
    }

    try {
      final profile = await _profileRepository.getProfileById(userId);
      if (profile != null) {
        _profileCache[userId] = profile;
        notifyListeners();
      }
    } catch (e) {
      log('Error fetching profile for $userId', name: 'ProfileProvider', error: e);
      return null;
    }

    if (!_profileSubscriptions.containsKey(userId)) {
      _profileSubscriptions[userId] =
          _profileRepository.getProfileStreamById(userId).listen(
        (profile) {
          _profileCache[userId] = profile;
          notifyListeners();
        },
        onError: (e) {
          log('Error listening to profile stream for $userId', name: 'ProfileProvider', error: e);
        },
      );
    }

    return _profileCache[userId];
  }

  /// 현재 로컬 사용자의 전체 프로필 정보를 서버에서 불러옵니다.
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_localUserId == null) {
      _error = '로컬 사용자 ID를 찾을 수 없습니다.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _currentProfile = await _profileRepository.getMyProfile(_localUserId!);
      await _profileRepository.updateUserPresence(
          userId: _localUserId!, isOnline: true);
    } catch (e) {
      _error = '프로필 로딩에 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 현재 사용자의 프로필 정보(닉네임, 상태 메시지)를 업데이트합니다.
  Future<void> updateProfile({String? nickname, String? statusMessage}) async {
    if (_localUserId == null) {
      _error = '로컬 사용자 ID를 찾을 수 없습니다. 로그인 상태를 확인해주세요.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newProfile = Profile(
        id: _localUserId!,
        nickname: nickname ?? _currentProfile?.nickname ?? '',
        avatarUrl: _currentProfile?.avatarUrl,
        statusMessage: statusMessage ?? _currentProfile?.statusMessage,
        lastSeen: _currentProfile?.lastSeen,
        isOnline: _currentProfile?.isOnline ?? false,
      );
      await _profileRepository.upsertProfile(newProfile);
      await loadProfile(); // 변경 사항을 즉시 반영하기 위해 프로필 다시 로드
    } catch (e) {
      _error = '프로필 업데이트에 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 현재 사용자의 아바타 이미지를 업로드하고 프로필을 업데이트합니다.
  ///
  /// [imageFile] 업로드할 이미지 파일입니다.
  Future<void> uploadAvatar(XFile imageFile) async {
    if (_localUserId == null) {
      _error = '로컬 사용자 ID를 찾을 수 없습니다. 로그인 상태를 확인해주세요.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final imageUrl =
          await _profileRepository.uploadAvatar(imageFile, _localUserId!);
      final newProfile = Profile(
        id: _localUserId!,
        nickname: _currentProfile?.nickname ?? '',
        avatarUrl: imageUrl,
        statusMessage: _currentProfile?.statusMessage,
        lastSeen: _currentProfile?.lastSeen,
        isOnline: _currentProfile?.isOnline ?? false,
      );
      await _profileRepository.upsertProfile(newProfile);
      await loadProfile(); // 변경 사항을 즉시 반영하기 위해 프로필 다시 로드
    } catch (e) {
      _error = '아바타 업로드에 실패했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 사용자의 접속 상태를 업데이트합니다. (내부 로직용)
  ///
  /// [isOnline] 온라인 상태 여부입니다.
  /// [lastSeen] 마지막 접속 시간입니다.
  Future<void> updateUserPresence(
      {required bool isOnline, DateTime? lastSeen}) async {
    if (_localUserId == null) return;
    try {
      await _profileRepository.updateUserPresence(
        userId: _localUserId!,
        isOnline: isOnline,
        lastSeen: lastSeen,
      );
      // 로컬 프로필 캐시도 업데이트하여 UI에 즉시 반영합니다.
      _currentProfile = _currentProfile?.copyWith(
          isOnline: isOnline, lastSeen: lastSeen ?? DateTime.now());
      notifyListeners();
    } catch (e) {
      log('Error updating user presence', name: 'ProfileProvider', error: e);
    }
  }
}