import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';

class ChatProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _messagesTableName = 'messages';

  Stream<List<Message>>? _messagesStream;
  String _currentNickname = '익명';
  String? _myLocalUserId;
  bool _isInitialized = false;
  String? _error;

  Stream<List<Message>>? get messagesStream => _messagesStream;
  String get currentNickname => _currentNickname;
  String? get myLocalUserId => _myLocalUserId;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get shouldShowNicknameDialog => _isInitialized && _currentNickname == '익명';

  ChatProvider();

  Future<void> initialize() async {
    try {
      _messagesStream = _supabase
          .from(_messagesTableName)
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: true)
          .map((data) => data.map((item) => Message.fromJson(item)).toList());

      await _loadLocalUserId();
      await _loadNickname();
      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = '초기화에 실패했습니다: $e';
      if (kDebugMode) {
        print(_error);
      }
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
      if (kDebugMode) {
        print(_error);
      }
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
      if (kDebugMode) {
        print(_error);
      }
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
      if (kDebugMode) {
        print(_error);
      }
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _myLocalUserId == null) return;

    try {
      await _supabase.from(_messagesTableName).insert({
        'content': content.trim(),
        'sender': _currentNickname,
        'local_user_id': _myLocalUserId,
      });
    } catch (e) {
      _error = '메시지 전송에 실패했습니다: $e';
      if (kDebugMode) {
        print(_error);
      }
      rethrow;
    }
  }
}
