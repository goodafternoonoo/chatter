import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import 'package:my_chat_app/constants/app_constants.dart';

class ChatProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  late final Stream<List<Message>> messagesStream;
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

  ChatProvider() {
    messagesStream = _supabase
        .from(AppConstants.messagesTableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => data.map((item) => Message.fromJson(item)).toList());
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

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _myLocalUserId == null) return;

    try {
      await _supabase.from(AppConstants.messagesTableName).insert({
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
