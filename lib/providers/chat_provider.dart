import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import 'package:my_chat_app/constants/app_constants.dart';
import 'package:my_chat_app/utils/notification_service.dart';
import 'package:my_chat_app/repositories/chat_repository.dart';

class ChatProvider with ChangeNotifier {
  final String roomId;
  final ChatRepository _chatRepository;

  List<Message> _messages = [];
  StreamSubscription<List<Message>>? _messageSubscription;
  String _currentNickname = AppConstants.defaultNickname;
  String? _myLocalUserId;
  bool _isInitialized = false;
  String? _error;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;

  // UI (ListView reverse:true)에 맞게 데이터는 최신순 -> 오래된순 으로 관리
  List<Message> get messages => _messages;
  String get currentNickname => _currentNickname;
  String? get myLocalUserId => _myLocalUserId;
  bool get isInitialized => _isInitialized;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreMessages => _hasMoreMessages;
  String? get error => _error;
  bool get shouldShowNicknameDialog =>
      _isInitialized && _currentNickname == AppConstants.defaultNickname;

  ChatProvider({required this.roomId, ChatRepository? chatRepository})
    : _chatRepository =
          chatRepository ?? ChatRepository(Supabase.instance.client);

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    try {
      _myLocalUserId = await _chatRepository.loadLocalUserId();
      _currentNickname =
          await _chatRepository.loadNickname() ?? AppConstants.defaultNickname;
      await _fetchInitialMessages();
      _subscribeToNewMessages();
      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = '초기화에 실패했습니다: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _fetchInitialMessages() async {
    if (roomId.isEmpty) return;
    const int limit = 20;
    final messagesFromServer = await _chatRepository.fetchLatestMessages(
      roomId: roomId,
      limit: limit + 1, // Fetch one extra to check for more pages
    );

    _hasMoreMessages = messagesFromServer.length > limit;
    _messages = _sortAndDeduplicateMessages(
      messagesFromServer.take(limit).toList(),
    );
    notifyListeners();
  }

  void _subscribeToNewMessages() {
    if (roomId.isEmpty) return;
    _messageSubscription = _chatRepository.getMessagesStream(roomId).listen((
      newMessages,
    ) {
      if (newMessages.isNotEmpty) {
        final existingIds = _messages.map((m) => m.id).toSet();
        final latestMessageInList = _messages.isNotEmpty
            ? _messages.first.createdAt
            : DateTime.fromMillisecondsSinceEpoch(0);

        // 스트림에서 기존에 없는 메시지이면서, 현재 리스트의 최신 메시지보다 새로운 메시지만 필터링
        final trulyNewMessages = newMessages
            .where(
              (m) =>
                  !existingIds.contains(m.id) &&
                  m.createdAt.isAfter(latestMessageInList) &&
                  !m.isDeleted, // isDeleted 필터 추가
            )
            .toList();

        if (trulyNewMessages.isNotEmpty) {
          _messages = _sortAndDeduplicateMessages(_messages + trulyNewMessages);

          final latestMessage = _messages.first;
          if (latestMessage.localUserId != _myLocalUserId &&
              WidgetsBinding.instance.lifecycleState !=
                  AppLifecycleState.resumed) {
            NotificationService.showNotification(
              notificationId: roomId.hashCode,
              title: latestMessage.localUserId,
              body: latestMessage.content,
            );
          }
          notifyListeners();
        }
      }
    });
  }

  List<Message> _sortAndDeduplicateMessages(List<Message> messagesToProcess) {
    // ID를 기준으로 중복 제거
    final uniqueMessages = <String, Message>{};
    for (var msg in messagesToProcess) {
      uniqueMessages[msg.id] = msg;
    }
    List<Message> result = uniqueMessages.values.toList();

    // created_at을 기준으로 최신순(내림차순) 정렬
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore ||
        !_hasMoreMessages ||
        roomId.isEmpty ||
        _messages.isEmpty) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      const int limit = 20;
      // 커서는 현재 가장 오래된 메시지(리스트의 마지막)를 기준으로 설정
      final oldestMessageCursor = _messages.last.createdAt;
      final olderMessagesFromServer = await _chatRepository
          .fetchPreviousMessages(
            roomId: roomId,
            cursor: oldestMessageCursor,
            limit: limit + 1, // Fetch one extra to check for more pages
          );

      _hasMoreMessages = olderMessagesFromServer.length > limit;
      final newMessages = olderMessagesFromServer.take(limit).toList();

      _messages = _sortAndDeduplicateMessages(_messages + newMessages);
    } catch (e) {
      _error = '이전 메시지를 불러오는 데 실패했습니다: $e';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> saveNickname(String nickname) async {
    if (nickname.trim().isEmpty) return;
    try {
      await _chatRepository.saveNickname(nickname.trim());
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
        localUserId: _myLocalUserId!,
        imageUrl: imageUrl,
      );
    } catch (e) {
      _error = '메시지 전송에 실패했습니다: $e';
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  Future<String> uploadImage(XFile imageFile) async {
    try {
      return await _chatRepository.uploadImage(imageFile);
    } catch (e) {
      _error = '이미지 업로드에 실패했습니다: $e';
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    if (_myLocalUserId == null) return;

    try {
      await _chatRepository.markMessageAsRead(messageId, _myLocalUserId!);
    } catch (e) {
      _error = '메시지 읽음 처리 실패: $e';
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatRepository.markMessageAsDeleted(messageId);
      // 로컬 메시지 목록에서 해당 메시지를 isDeleted = true로 업데이트
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = Message(
          id: _messages[index].id,
          content: _messages[index].content,
          localUserId: _messages[index].localUserId,
          createdAt: _messages[index].createdAt,
          readBy: _messages[index].readBy,
          imageUrl: _messages[index].imageUrl,
          isDeleted: true, // isDeleted 필드를 true로 설정
        );
        notifyListeners();
      }
    } catch (e) {
      _error = '메시지 삭제 실패: $e';
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }
}
