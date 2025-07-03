import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';

class ChatProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _messagesTableName = 'messages';

  late final Stream<List<Message>> messagesStream;
  String _currentNickname = '익명';
  String? _myLocalUserId;
  bool _isInitialized = false;

  String get currentNickname => _currentNickname;
  String? get myLocalUserId => _myLocalUserId;
  bool get isInitialized => _isInitialized;
  bool get shouldShowNicknameDialog => _isInitialized && _currentNickname == '익명';

  ChatProvider() {
    // 생성자에서 초기화 호출 제거
  }

  Future<void> initialize() async { // public 메서드로 변경
    messagesStream = _supabase
        .from(_messagesTableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => data.map((item) => Message.fromJson(item)).toList());

    await _loadLocalUserId();
    await _loadNickname();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _myLocalUserId = prefs.getString('local_user_id');
    if (_myLocalUserId == null) {
      _myLocalUserId = const Uuid().v4();
      await prefs.setString('local_user_id', _myLocalUserId!);
    }
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNickname = prefs.getString('nickname');
    if (savedNickname != null && savedNickname.isNotEmpty) {
      _currentNickname = savedNickname;
    }
  }

  Future<void> saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', nickname);
    _currentNickname = nickname;
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _myLocalUserId == null) return;

    await _supabase.from(_messagesTableName).insert({
      'content': content.trim(),
      'sender': _currentNickname,
      'local_user_id': _myLocalUserId,
    });
  }
}
