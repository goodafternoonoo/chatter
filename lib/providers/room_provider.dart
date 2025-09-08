import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:my_chat_app/models/room.dart';
import 'package:my_chat_app/repositories/room_repository.dart';
import 'package:my_chat_app/providers/profile_provider.dart';
import 'package:my_chat_app/repositories/chat_repository.dart';

/// 채팅방 목록의 상태를 관리하는 클래스입니다.
///
/// 채팅방 목록을 실시간으로 가져오고, 각 방의 마지막 메시지 및
/// 읽지 않은 메시지 수를 계산하여 UI에 제공하는 역할을 합니다.
class RoomProvider with ChangeNotifier {
  final RoomRepository _roomRepository;
  final ProfileProvider _profileProvider;
  final ChatRepository _chatRepository;

  /// `rooms` 테이블의 변경 사항을 구독하는 스트림입니다.
  StreamSubscription<List<Room>>? _roomSubscription;

  /// 각 채팅방의 메시지 스트림을 개별적으로 구독하고 관리하는 맵입니다.
  ///
  /// `roomId`를 키로 사용하여 각 방의 `StreamSubscription`을 저장합니다.
  /// 이를 통해 특정 방에 새 메시지가 도착했을 때 해당 방의 정보만 효율적으로 업데이트할 수 있습니다.
  final Map<String, StreamSubscription<List<dynamic>>> _messageSubscriptions = {};

  /// UI에 표시될 채팅방 목록입니다.
  List<Room> _rooms = [];

  /// 데이터 로딩 중인지 여부를 나타냅니다.
  bool _isLoading = true;

  /// 발생한 오류 메시지를 저장합니다.
  String? _error;

  /// {@template room_provider}
  /// `RoomProvider`의 인스턴스를 생성합니다.
  ///
  /// 생성과 동시에 `_listenToRooms`를 호출하여 채팅방 목록 구독을 시작합니다.
  /// {@endtemplate}
  RoomProvider({
    required RoomRepository roomRepository,
    required ProfileProvider profileProvider,
    required ChatRepository chatRepository,
  })  : _roomRepository = roomRepository,
        _profileProvider = profileProvider,
        _chatRepository = chatRepository {
    _listenToRooms();
  }

  /// UI에 표시될 채팅방 목록을 반환합니다.
  List<Room> get rooms => _rooms;

  /// 현재 로딩 상태를 반환합니다.
  bool get isLoading => _isLoading;

  /// 마지막 오류 메시지를 반환합니다.
  String? get error => _error;

  /// 채팅방 목록 스트림을 구독하고, 각 방의 상세 정보를 업데이트합니다.
  void _listenToRooms() {
    _isLoading = true;
    notifyListeners();

    _roomSubscription = _roomRepository.getRoomStream().listen((rooms) async {
      // 새로운 방 목록이 도착하면, 각 방의 추가 정보(마지막 메시지, 안 읽은 개수)를 가져옵니다.
      final List<Room> newRooms = [];
      for (var room in rooms) {
        final lastMessage =
            await _chatRepository.fetchLastMessageForRoom(room.id);
        final unreadCount = await _calculateUnreadCount(room.id);
        newRooms.add(Room(
          id: room.id,
          name: room.name,
          createdAt: room.createdAt,
          unreadCount: unreadCount,
          lastMessageContent: lastMessage?.content,
          lastMessageCreatedAt: lastMessage?.createdAt,
        ));
      }
      _rooms = newRooms;
      _isLoading = false;
      _error = null;
      notifyListeners();

      // 각 방에 대한 메시지 스트림을 구독하여 실시간 업데이트를 준비합니다.
      for (var room in _rooms) {
        _subscribeToRoomMessages(room.id);
      }

      // 더 이상 존재하지 않는 방의 구독은 해지하여 리소스를 정리합니다.
      final List<String> roomsToRemove = [];
      for (var roomId in _messageSubscriptions.keys) {
        if (!_rooms.any((room) => room.id == roomId)) {
          roomsToRemove.add(roomId);
        }
      }
      for (var roomId in roomsToRemove) {
        _messageSubscriptions[roomId]?.cancel();
        _messageSubscriptions.remove(roomId);
      }
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  /// 특정 채팅방의 메시지 스트림을 구독합니다.
  ///
  /// 이미 구독 중인 방은 중복 구독하지 않습니다.
  /// 해당 방에 메시지 변경이 감지되면, `_updateRoomUnreadCountAndLastMessage`를 호출하여
  /// UI에 표시될 정보를 갱신합니다.
  ///
  /// [roomId] 구독할 채팅방의 ID입니다.
  void _subscribeToRoomMessages(String roomId) {
    if (_messageSubscriptions.containsKey(roomId)) {
      return;
    }

    _messageSubscriptions[roomId] =
        _chatRepository.getMessagesStream(roomId).listen((messages) async {
      await _updateRoomUnreadCountAndLastMessage(roomId);
    }, onError: (e) {
      log('Error listening to messages for room $roomId', name: 'RoomProvider', error: e);
    });
  }

  /// 특정 방의 읽지 않은 메시지 수와 마지막 메시지를 다시 계산하여 상태를 업데이트합니다.
  ///
  /// [roomId] 업데이트할 채팅방의 ID입니다.
  Future<void> _updateRoomUnreadCountAndLastMessage(String roomId) async {
    final unreadCount = await _calculateUnreadCount(roomId);
    final lastMessage = await _chatRepository.fetchLastMessageForRoom(roomId);
    final index = _rooms.indexWhere((room) => room.id == roomId);
    if (index != -1) {
      _rooms[index] = Room(
        id: _rooms[index].id,
        name: _rooms[index].name,
        createdAt: _rooms[index].createdAt,
        unreadCount: unreadCount,
        lastMessageContent: lastMessage?.content,
        lastMessageCreatedAt: lastMessage?.createdAt,
      );
      notifyListeners();
    }
  }

  /// 특정 방의 읽지 않은 메시지 수를 계산합니다.
  ///
  /// [roomId] 계산할 채팅방의 ID입니다.
  ///
  /// 현재 사용자가 보내지 않았고, 아직 읽지 않은 메시지의 개수를 반환합니다.
  Future<int> _calculateUnreadCount(String roomId) async {
    final currentUserId = _profileProvider.currentLocalUserId;
    if (currentUserId == null) return 0;

    // 성능을 위해 최근 100개의 메시지만 확인합니다.
    final messages =
        await _chatRepository.fetchLatestMessages(roomId: roomId, limit: 100);
    int unreadCount = 0;
    for (var message in messages) {
      if (!message.readBy.contains(currentUserId) &&
          message.localUserId != currentUserId) {
        unreadCount++;
      }
    }
    return unreadCount;
  }

  /// 새로운 채팅방을 생성합니다.
  ///
  /// [name] 생성할 채팅방의 이름입니다.
  Future<void> createRoom(String name) async {
    try {
      await _roomRepository.createRoom(name);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 특정 채팅방을 삭제합니다.
  ///
  /// [roomId] 삭제할 채팅방의 ID입니다.
  Future<void> deleteRoom(String roomId) async {
    try {
      await _roomRepository.deleteRoom(roomId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    for (var subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();
    super.dispose();
  }
}
