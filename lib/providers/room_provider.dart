import 'dart:async';
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
      final updatedRooms = <Room>[];
      for (var room in rooms) {
        final unreadCount = await _calculateUnreadCount(room.id);
        updatedRooms.add(Room(
          id: room.id,
          name: room.name,
          createdAt: room.createdAt,
          unreadCount: unreadCount,
        ));
      }
      _rooms = updatedRooms;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
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
    super.dispose();
  }
}
