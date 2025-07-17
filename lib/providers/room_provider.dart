import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_chat_app/models/room.dart';
import 'package:my_chat_app/repositories/room_repository.dart';

class RoomProvider with ChangeNotifier {
  final RoomRepository _roomRepository;
  StreamSubscription<List<Room>>? _roomSubscription;
  List<Room> _rooms = [];
  bool _isLoading = true;
  String? _error;

  RoomProvider({required RoomRepository roomRepository})
      : _roomRepository = roomRepository {
    _listenToRooms();
  }

  List<Room> get rooms => _rooms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _listenToRooms() {
    _isLoading = true;
    notifyListeners();
    _roomSubscription = _roomRepository.getRoomStream().listen((rooms) {
      _rooms = rooms;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
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
