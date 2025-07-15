import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import 'package:my_chat_app/constants/app_constants.dart';
import 'package:my_chat_app/utils/notification_service.dart';
import 'package:my_chat_app/repositories/chat_repository.dart'; // ChatRepository 임포트

class ChatProvider with ChangeNotifier {
  final String roomId;
  final ChatRepository _chatRepository; // ChatRepository 인스턴스 추가

  late final Stream<List<Message>> messagesStream;
  StreamSubscription<List<Message>>? _messageSubscription;
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

  ChatProvider({required this.roomId, ChatRepository? chatRepository}) // ChatRepository를 주입받도록 변경
      : _chatRepository = chatRepository ?? ChatRepository(Supabase.instance.client) {
    if (roomId.isNotEmpty) {
      messagesStream = _chatRepository.getMessagesStream(roomId); // ChatRepository 사용

      _messageSubscription = messagesStream.listen((messages) {
        if (messages.isNotEmpty) {
          final latestMessage = messages.last;
          if (latestMessage.localUserId != _myLocalUserId &&
              WidgetsBinding.instance.lifecycleState !=
                  AppLifecycleState.resumed) {
            NotificationService.showNotification(
              notificationId: roomId.hashCode,
              title: latestMessage.sender,
              body: latestMessage.content,
            );
          }
        }
      });
    } else {
      messagesStream = const Stream.empty();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    try {
      _myLocalUserId = await _chatRepository.loadLocalUserId(); // ChatRepository 사용
      _currentNickname = await _chatRepository.loadNickname() ?? AppConstants.defaultNickname; // ChatRepository 사용
      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = '초기화에 실패했습니다: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveNickname(String nickname) async {
    if (nickname.trim().isEmpty) return;
    try {
      await _chatRepository.saveNickname(nickname.trim()); // ChatRepository 사용
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
      await _chatRepository.sendMessage(
        roomId: roomId,
        content: content.trim(),
        sender: _currentNickname,
        localUserId: _myLocalUserId!,
        imageUrl: imageUrl,
      ); // ChatRepository 사용
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
      return await _chatRepository.uploadImage(imageFile); // ChatRepository 사용
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
      await _chatRepository.markMessageAsRead(messageId, _myLocalUserId!); // ChatRepository 사용
    } catch (e) {
      _error = '메시지 읽음 처리 실패: $e';
      if (kDebugMode) {
        print(_error);
      }
      rethrow;
    }
  }
}