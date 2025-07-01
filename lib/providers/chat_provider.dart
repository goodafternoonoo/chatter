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

  String get currentNickname => _currentNickname;
  String? get myLocalUserId => _myLocalUserId;

  ChatProvider() {
    _initialize();
  }

  void _initialize() {
    messagesStream = _supabase
        .from(_messagesTableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => data.map((item) => Message.fromJson(item)).toList());

    _loadLocalUserId();
    _loadNickname();
  }

  Future<void> _loadLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _myLocalUserId = prefs.getString('local_user_id');
    if (_myLocalUserId == null) {
      _myLocalUserId = const Uuid().v4();
      await prefs.setString('local_user_id', _myLocalUserId!);
    }
    notifyListeners();
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNickname = prefs.getString('nickname');
    if (savedNickname != null && savedNickname.isNotEmpty) {
      _currentNickname = savedNickname;
    }
    notifyListeners();
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
