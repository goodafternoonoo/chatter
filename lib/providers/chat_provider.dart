import 'dart:async';
import 'dart:io'; // File 사용을 위해 추가
import 'package:image_picker/image_picker.dart'; // XFile 사용을 위해 추가
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // WidgetsBinding, AppLifecycleState 사용을 위해 추가
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import 'package:my_chat_app/constants/app_constants.dart';

import 'package:my_chat_app/utils/notification_service.dart'; // NotificationService 임포트

class ChatProvider with ChangeNotifier {
  final String roomId;
  final SupabaseClient _supabase = Supabase.instance.client;

  late final Stream<List<Message>> messagesStream;
  StreamSubscription<List<Message>>? _messageSubscription; // 구독 관리
  String _currentNickname = AppConstants.defaultNickname;
  String? _myLocalUserId;
  bool _isInitialized = false;
  String? _error;

  String get currentNickname => _currentNickname;
  String? get myLocalUserId => _myLocalUserId;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get shouldShowNicknameDialog =>
      _isInitialized && _currentNickname == AppConstants.defaultNickname;

  ChatProvider({required this.roomId}) {
    if (roomId.isNotEmpty) {
      messagesStream = _supabase
          .from(AppConstants.messagesTableName)
          .stream(primaryKey: ['id'])
          .eq('room_id', roomId) // roomId로 필터링
          .order('created_at', ascending: true)
          .map((data) => data.map((item) => Message.fromJson(item)).toList());

      _messageSubscription = messagesStream.listen((messages) {
        if (messages.isNotEmpty) {
          final latestMessage = messages.last;
          // 내가 보낸 메시지가 아니고, 앱이 백그라운드에 있을 때만 알림 표시
          if (latestMessage.localUserId != _myLocalUserId &&
              WidgetsBinding.instance.lifecycleState !=
                  AppLifecycleState.resumed) {
            NotificationService.showNotification(
              notificationId: roomId.hashCode, // 채팅방 ID를 기반으로 고유 ID 생성
              title: latestMessage.sender,
              body: latestMessage.content,
            );
          }
        }
      });
    } else {
      messagesStream = const Stream.empty(); // 빈 스트림으로 초기화
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel(); // 구독 취소
    super.dispose();
  }

  Future<void> initialize() async {
    try {
      await _loadLocalUserId();
      await _loadNickname();
      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = '초기화에 실패했습니다: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadLocalUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _myLocalUserId = prefs.getString('local_user_id');
      if (_myLocalUserId == null) {
        _myLocalUserId = const Uuid().v4();
        await prefs.setString('local_user_id', _myLocalUserId!);
      }
    } catch (e) {
      _error = '로컬 사용자 ID 로딩에 실패했습니다: $e';
      rethrow;
    }
  }

  Future<void> _loadNickname() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNickname = prefs.getString('nickname');
      if (savedNickname != null && savedNickname.isNotEmpty) {
        _currentNickname = savedNickname;
      }
    } catch (e) {
      _error = '닉네임 로딩에 실패했습니다: $e';
      rethrow;
    }
  }

  Future<void> saveNickname(String nickname) async {
    if (nickname.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nickname', nickname.trim());
      _currentNickname = nickname.trim();
      _error = null;
    } catch (e) {
      _error = '닉네임 저장에 실패했습니다: $e';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content, {String? imageUrl}) async {
    if (content.trim().isEmpty && imageUrl == null || _myLocalUserId == null) {
      return;
    }

    try {
      await _supabase.from(AppConstants.messagesTableName).insert({
        'room_id': roomId, // room_id 추가
        'content': content.trim(),
        'sender': _currentNickname,
        'local_user_id': _myLocalUserId,
        'image_url': imageUrl, // image_url 추가
      });
    } catch (e) {
      _error = '메시지 전송에 실패했습니다: $e';
      if (kDebugMode) {
        print(_error);
      }
      rethrow;
    }
  }

  Future<String> uploadImage(XFile imageFile) async {
    try {
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
    } catch (e) {
      _error = '이미지 업로드에 실패했습니다: $e';
      if (kDebugMode) {
        print(_error);
      }
      rethrow;
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    if (_myLocalUserId == null) return;

    try {
      // 1. 메시지 가져오기
      final List<dynamic> response = await _supabase
          .from(AppConstants.messagesTableName)
          .select('read_by')
          .eq('id', messageId)
          .limit(1);

      if (response.isEmpty) return; // 메시지를 찾을 수 없음

      final currentReadBy = (response[0]['read_by'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();

      // 2. 이미 읽었는지 확인
      if (currentReadBy.contains(_myLocalUserId)) {
        return; // 이미 읽음 처리됨
      }

      // 3. 사용자 ID 추가
      final newReadBy = List<String>.from(currentReadBy);
      newReadBy.add(_myLocalUserId!);

      // 4. 메시지 업데이트
      await _supabase
          .from(AppConstants.messagesTableName)
          .update({'read_by': newReadBy})
          .eq('id', messageId);
    } catch (e) {
      _error = '메시지 읽음 처리 실패: $e';
      if (kDebugMode) {
        print(_error);
      }
      rethrow;
    }
  }
}
