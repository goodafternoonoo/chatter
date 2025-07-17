import 'dart:async';
import 'dart:developer'; // dart:developer 임포트
import 'package:flutter/material.dart';
import 'package:my_chat_app/models/room.dart';
import 'package:my_chat_app/repositories/room_repository.dart';
import 'package:my_chat_app/providers/profile_provider.dart';
import 'package:my_chat_app/repositories/chat_repository.dart';

class RoomProvider with ChangeNotifier {
  final RoomRepository _roomRepository;
  final ProfileProvider _profileProvider;
  final ChatRepository _chatRepository;
  StreamSubscription<List<Room>>? _roomSubscription;
  final Map<String, StreamSubscription<List<dynamic>>> _messageSubscriptions = {}; // 각 방의 메시지 스트림 구독 관리
  List<Room> _rooms = [];
  bool _isLoading = true;
  String? _error;

  RoomProvider({
    required RoomRepository roomRepository,
    required ProfileProvider profileProvider,
    required ChatRepository chatRepository,
  })
      : _roomRepository = roomRepository,
        _profileProvider = profileProvider,
        _chatRepository = chatRepository {
    _listenToRooms();
  }

  List<Room> get rooms => _rooms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _listenToRooms() {
    _isLoading = true;
    notifyListeners();
    _roomSubscription = _roomRepository.getRoomStream().listen((rooms) async {
      final List<Room> newRooms = [];
      for (var room in rooms) {
        final lastMessage = await _chatRepository.fetchLastMessageForRoom(room.id);
        final unreadCount = await _calculateUnreadCount(room.id); // 읽지 않은 메시지 수 계산
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

      // 각 방의 메시지 스트림 구독 시작 또는 업데이트
      for (var room in _rooms) {
        _subscribeToRoomMessages(room.id);
      }
      // 더 이상 존재하지 않는 방의 구독 해지
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

  void _subscribeToRoomMessages(String roomId) {
    if (_messageSubscriptions.containsKey(roomId)) {
      return; // 이미 구독 중이면 다시 구독하지 않음
    }

    _messageSubscriptions[roomId] = _chatRepository.getMessagesStream(roomId).listen((messages) async {
      // 메시지 스트림에서 변경이 감지되면 해당 방의 읽지 않은 메시지 수와 마지막 메시지 업데이트
      await _updateRoomUnreadCountAndLastMessage(roomId);
    }, onError: (e) {
      // 메시지 스트림 에러 처리
      log('Error listening to messages for room $roomId', name: 'RoomProvider', error: e);
    });
  }

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

  Future<int> _calculateUnreadCount(String roomId) async {
    final currentUserId = _profileProvider.currentLocalUserId;
    if (currentUserId == null) return 0;

    final messages = await _chatRepository.fetchLatestMessages(roomId: roomId, limit: 100); // 최근 100개 메시지 기준
    int unreadCount = 0;
    for (var message in messages) {
      if (!message.readBy.contains(currentUserId) && message.localUserId != currentUserId) {
        unreadCount++;
      }
    }
    return unreadCount;
  }

  Future<void> createRoom(String name) async {
    try {
      await _roomRepository.createRoom(name);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

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
