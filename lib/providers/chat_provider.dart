import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import 'package:my_chat_app/utils/notification_service.dart';
import 'package:my_chat_app/repositories/chat_repository.dart';
import 'package:my_chat_app/providers/profile_provider.dart';

/// 특정 채팅방의 상태를 관리하는 클래스입니다.
///
/// 메시지 목록 관리, 실시간 메시지 수신, 메시지 전송, 검색, 무한 스크롤 등
/// 채팅 페이지에 필요한 모든 비즈니스 로직을 담당합니다.
class ChatProvider with ChangeNotifier {
  /// 이 Provider가 관리하는 채팅방의 ID입니다.
  final String roomId;

  /// 채팅 관련 데이터 통신을 담당하는 리포지토리입니다.
  final ChatRepository _chatRepository;

  /// 현재 사용자 프로필 정보에 접근하기 위한 프로바이더입니다.
  final ProfileProvider _profileProvider;

  /// UI에 표시될 메시지 목록입니다. 최신순으로 정렬됩니다.
  List<Message> _messages = [];

  /// 메시지 스트림을 구독하고 관리하기 위한 객체입니다.
  StreamSubscription<List<Message>>? _messageSubscription;

  /// Provider가 성공적으로 초기화되었는지 여부를 나타냅니다.
  bool _isInitialized = false;

  /// 발생한 오류 메시지를 저장합니다.
  String? _error;

  /// 이전 메시지를 불러오는 중인지 여부를 나타냅니다.
  bool _isLoadingMore = false;

  /// 서버에 더 불러올 메시지가 있는지 여부를 나타냅니다.
  bool _hasMoreMessages = true;

  /// 현재 검색어입니다.
  String _searchQuery = '';

  /// 검색 결과 메시지 목록입니다.
  List<Message> _searchResults = [];

  /// 현재 메시지를 검색 중인지 여부를 나타냅니다.
  bool _isSearching = false;

  /// UI에 표시될 메시지 목록을 반환합니다. (최신순)
  List<Message> get messages => _messages;

  /// Provider의 초기화 완료 여부를 반환합니다.
  bool get isInitialized => _isInitialized;

  /// 이전 메시지를 불러오는 중인지 여부를 반환합니다.
  bool get isLoadingMore => _isLoadingMore;

  /// 더 불러올 메시지가 있는지 여부를 반환합니다.
  bool get hasMoreMessages => _hasMoreMessages;

  /// 마지막으로 발생한 오류 메시지를 반환합니다.
  String? get error => _error;

  /// 현재 검색어를 반환합니다.
  String get searchQuery => _searchQuery;

  /// 검색 결과 목록을 반환합니다.
  List<Message> get searchResults => _searchResults;

  /// 검색 중인지 여부를 반환합니다.
  bool get isSearching => _isSearching;

  /// {@template chat_provider}
  /// `ChatProvider`의 인스턴스를 생성합니다.
  ///
  /// [roomId] 관리할 채팅방의 ID입니다.
  /// [chatRepository] 사용할 채팅 리포지토리입니다. 제공되지 않으면 기본 인스턴스를 생성합니다.
  /// [profileProvider] 현재 사용자 정보를 얻기 위한 프로필 프로바이더입니다.
  /// {@endtemplate}
  ChatProvider({
    required this.roomId,
    ChatRepository? chatRepository,
    required ProfileProvider profileProvider,
  })  : _chatRepository =
            chatRepository ?? ChatRepository(Supabase.instance.client),
        _profileProvider = profileProvider;

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  /// Provider를 초기화합니다.
  ///
  /// 초기 메시지를 불러오고, 새로운 메시지에 대한 실시간 구독을 시작합니다.
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

  /// 채팅방의 초기 메시지 목록을 서버에서 가져옵니다.
  Future<void> _fetchInitialMessages() async {
    if (roomId.isEmpty) return;
    const int limit = 20;
    // 다음 페이지가 있는지 확인하기 위해 limit보다 하나 더 많이 요청합니다.
    final messagesFromServer = await _chatRepository.fetchLatestMessages(
      roomId: roomId,
      limit: limit + 1,
    );

    _hasMoreMessages = messagesFromServer.length > limit;
    _messages = _sortAndDeduplicateMessages(
      messagesFromServer.take(limit).toList(),
    );
    notifyListeners();
  }

  /// 새로운 메시지에 대한 실시간 스트림을 구독합니다.
  ///
  /// 새로운 메시지가 도착하거나 기존 메시지가 업데이트(예: 읽음 처리)될 때 UI를 갱신합니다.
  /// 앱이 백그라운드 상태일 때 새 메시지가 오면 로컬 알림을 표시합니다.
  void _subscribeToNewMessages() {
    if (roomId.isEmpty) return;
    _messageSubscription =
        _chatRepository.getMessagesStream(roomId).listen((newMessages) {
      if (newMessages.isNotEmpty) {
        final latestMessageInList = _messages.isNotEmpty
            ? _messages.first.createdAt
            : DateTime.fromMillisecondsSinceEpoch(0);

        final List<Message> messagesToUpdate = [];
        final List<Message> trulyNewMessages = [];

        for (var newMessage in newMessages) {
          final existingMessageIndex =
              _messages.indexWhere((m) => m.id == newMessage.id);
          if (existingMessageIndex != -1) {
            // 이미 있는 메시지라면, 정보가 변경되었는지 확인합니다. (예: readBy)
            if (_messages[existingMessageIndex].readBy.length !=
                newMessage.readBy.length) {
              messagesToUpdate.add(newMessage);
            }
          } else if (newMessage.createdAt.isAfter(latestMessageInList) &&
              !newMessage.isDeleted) {
            // 목록에 없는 새로운 메시지일 경우 추가합니다.
            trulyNewMessages.add(newMessage);
          }
        }

        if (trulyNewMessages.isNotEmpty || messagesToUpdate.isNotEmpty) {
          // 새로운 메시지를 목록의 맨 앞에 추가합니다.
          _messages = _sortAndDeduplicateMessages(_messages + trulyNewMessages);

          // 기존 메시지 정보를 업데이트합니다.
          for (var updatedMsg in messagesToUpdate) {
            final index =
                _messages.indexWhere((msg) => msg.id == updatedMsg.id);
            if (index != -1) {
              _messages[index] = updatedMsg;
            }
          }

          // 내가 보낸 메시지가 아니고 앱이 활성 상태가 아닐 때 알림을 보냅니다.
          final latestMessage = _messages.first;
          if (latestMessage.localUserId != _profileProvider.currentLocalUserId &&
              WidgetsBinding.instance.lifecycleState !=
                  AppLifecycleState.resumed) {
            NotificationService.showNotification(
              notificationId: roomId.hashCode,
              title: _profileProvider.currentProfile?.nickname ??
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

  /// 메시지 목록을 정렬하고 중복을 제거합니다.
  ///
  /// [messagesToProcess] 처리할 메시지 목록입니다.
  ///
  /// ID를 기준으로 중복을 제거하고, 생성 시간을 기준으로 최신순으로 정렬된 목록을 반환합니다.
  List<Message> _sortAndDeduplicateMessages(List<Message> messagesToProcess) {
    final uniqueMessages = <String, Message>{};
    for (var msg in messagesToProcess) {
      uniqueMessages[msg.id] = msg;
    }
    List<Message> result = uniqueMessages.values.toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// 이전 메시지를 추가로 불러옵니다. (무한 스크롤)
  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _messages.isEmpty) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      const int limit = 20;
      // 현재 목록에서 가장 오래된 메시지를 기준으로 이전 데이터를 요청합니다.
      final oldestMessageCursor = _messages.last.createdAt;
      final olderMessagesFromServer =
          await _chatRepository.fetchPreviousMessages(
        roomId: roomId,
        cursor: oldestMessageCursor,
        limit: limit + 1,
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

  /// 텍스트 또는 이미지 메시지를 전송합니다.
  ///
  /// [content] 전송할 텍스트 내용입니다.
  /// [imageUrl] 전송할 이미지의 URL입니다.
  Future<void> sendMessage(String content, {String? imageUrl}) async {
    if (_profileProvider.currentLocalUserId == null) return;
    if (content.trim().isEmpty && imageUrl == null) return;

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

  /// 이미지를 서버에 업로드합니다.
  ///
  /// [imageFile] 업로드할 이미지 파일입니다.
  ///
  /// 업로드된 이미지의 공개 URL을 반환합니다.
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

  /// 현재 채팅방의 모든 메시지를 읽음 처리합니다.
  Future<void> markAllMessagesAsRead() async {
    if (_profileProvider.currentLocalUserId == null) return;

    final currentUserId = _profileProvider.currentLocalUserId!;
    // 현재 사용자가 아직 읽지 않은 메시지만 필터링합니다.
    final List<Message> messagesToUpdate =
        _messages.where((msg) => !msg.readBy.contains(currentUserId)).toList();

    if (messagesToUpdate.isEmpty) return;

    try {
      // 여러 메시지를 병렬로 읽음 처리하여 성능을 개선합니다.
      await Future.wait(messagesToUpdate.map(
        (message) =>
            _chatRepository.markMessageAsRead(message.id, currentUserId),
      ));

      // 서버 요청 성공 후 로컬 상태를 즉시 업데이트하여 UI에 빠르게 반영합니다.
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
    }
  }

  /// 특정 메시지를 논리적으로 삭제합니다.
  ///
  /// [messageId] 삭제할 메시지의 ID입니다.
  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatRepository.markMessageAsDeleted(messageId);
      // 로컬에서도 즉시 삭제된 것처럼 보이도록 상태를 업데이트합니다.
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = Message(
          id: _messages[index].id,
          content: _messages[index].content,
          localUserId: _messages[index].localUserId,
          createdAt: _messages[index].createdAt,
          readBy: _messages[index].readBy,
          imageUrl: _messages[index].imageUrl,
          isDeleted: true,
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

  /// 메시지 내용에서 특정 키워드를 검색합니다.
  ///
  /// [query] 검색할 키워드입니다.
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
