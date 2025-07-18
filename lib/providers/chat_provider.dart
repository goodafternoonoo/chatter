import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import 'package:my_chat_app/utils/notification_service.dart';
import 'package:my_chat_app/repositories/chat_repository.dart';
import 'package:my_chat_app/providers/profile_provider.dart'; // ProfileProvider 임포트

class ChatProvider with ChangeNotifier {
  final String roomId;
  final ChatRepository _chatRepository;
  final ProfileProvider _profileProvider; // ProfileProvider 인스턴스 추가

  List<Message> _messages = [];
  StreamSubscription<List<Message>>? _messageSubscription;
  bool _isInitialized = false;
  String? _error;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  String _searchQuery = ''; // 검색어 필드 추가
  List<Message> _searchResults = []; // 검색 결과 필드 추가
  bool _isSearching = false; // 검색 중 상태 필드 추가

  // UI (ListView reverse:true)에 맞게 데이터는 최신순 -> 오래된순 으로 관리
  List<Message> get messages => _messages;
  bool get isInitialized => _isInitialized;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreMessages => _hasMoreMessages;
  String? get error => _error;
  String get searchQuery => _searchQuery; // 검색어 getter 추가
  List<Message> get searchResults => _searchResults; // 검색 결과 getter 추가
  bool get isSearching => _isSearching; // 검색 중 상태 getter 추가

  ChatProvider({
    required this.roomId,
    ChatRepository? chatRepository,
    required ProfileProvider profileProvider,
  }) : _chatRepository =
           chatRepository ?? ChatRepository(Supabase.instance.client),
       _profileProvider = profileProvider;

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    try {
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
        final latestMessageInList = _messages.isNotEmpty
            ? _messages.first.createdAt
            : DateTime.fromMillisecondsSinceEpoch(0);

        final List<Message> messagesToUpdate = [];
        final List<Message> trulyNewMessages = [];

        for (var newMessage in newMessages) {
          final existingMessageIndex = _messages.indexWhere(
            (m) => m.id == newMessage.id,
          );
          if (existingMessageIndex != -1) {
            // 기존 메시지인 경우, readBy 필드 업데이트 여부 확인
            if (_messages[existingMessageIndex].readBy.length !=
                newMessage.readBy.length) {
              messagesToUpdate.add(newMessage);
            }
          } else if (newMessage.createdAt.isAfter(latestMessageInList) &&
              !newMessage.isDeleted) {
            // 새로운 메시지인 경우
            trulyNewMessages.add(newMessage);
          }
        }

        if (trulyNewMessages.isNotEmpty || messagesToUpdate.isNotEmpty) {
          // 새로운 메시지 추가
          _messages = _sortAndDeduplicateMessages(_messages + trulyNewMessages);

          // 기존 메시지 업데이트
          for (var updatedMsg in messagesToUpdate) {
            final index = _messages.indexWhere(
              (msg) => msg.id == updatedMsg.id,
            );
            if (index != -1) {
              _messages[index] = updatedMsg;
            }
          }

          final latestMessage = _messages.first;
          if (latestMessage.localUserId !=
                  _profileProvider.currentLocalUserId &&
              WidgetsBinding.instance.lifecycleState !=
                  AppLifecycleState.resumed) {
            NotificationService.showNotification(
              notificationId: roomId.hashCode,
              title:
                  _profileProvider.currentProfile?.nickname ??
                  latestMessage.localUserId ??
                  '알 수 없음',
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

  Future<void> sendMessage(String content, {String? imageUrl}) async {
    if (_profileProvider.currentLocalUserId == null) {
      return;
    }
    if (content.trim().isEmpty && imageUrl == null) {
      return;
    }

    try {
      await _chatRepository.sendMessage(
        roomId: roomId,
        content: content.trim(),
        localUserId: _profileProvider.currentLocalUserId,
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

  Future<void> markAllMessagesAsRead() async {
    if (_profileProvider.currentLocalUserId == null) return;

    final currentUserId = _profileProvider.currentLocalUserId!;
    final List<Message> messagesToUpdate = _messages
        .where((msg) => !msg.readBy.contains(currentUserId))
        .toList();

    if (messagesToUpdate.isEmpty) return;

    try {
      // 여러 메시지를 병렬로 읽음 처리
      await Future.wait(messagesToUpdate.map(
        (message) => _chatRepository.markMessageAsRead(message.id, currentUserId),
      ));

      // 로컬 상태를 즉시 업데이트하여 UI에 반영
      for (var message in messagesToUpdate) {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index].readBy.add(currentUserId);
        }
      }
      notifyListeners();

    } catch (e) {
      _error = '모든 메시지 읽음 처리 실패: $e';
      if (kDebugMode) {
        print(e);
      }
      // 에러를 다시 던지지 않고 UI에 오류를 표시하도록 처리
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

  Future<void> searchMessages(String query) async {
    _searchQuery = query.trim();
    if (_searchQuery.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _chatRepository.searchMessages(
        roomId: roomId,
        query: _searchQuery,
      );
    } catch (e) {
      _error = '메시지 검색에 실패했습니다: $e';
      if (kDebugMode) {
        print(e);
      }
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
}
