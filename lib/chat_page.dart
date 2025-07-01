import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'chat_message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  String _currentNickname = '익명'; // 현재 사용자 닉네임
  String? _myLocalUserId; // 현재 사용자의 로컬 고유 ID
  final _scrollController = ScrollController();
  bool _showScrollToBottomButton = false;
  bool _isInitialLoad = true;
  bool _isMessageEmpty = true;

  @override
  void initState() {
    super.initState();
    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => data);

    _scrollController.addListener(_scrollListener);
    _messageController.addListener(_onMessageChanged);

    _loadNickname();
    _loadLocalUserId();
  }

  Future<void> _loadLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? localUserId = prefs.getString('local_user_id');
    if (localUserId == null) {
      localUserId = const Uuid().v4();
      await prefs.setString('local_user_id', localUserId);
    }
    setState(() {
      _myLocalUserId = localUserId;
    });
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNickname = prefs.getString('nickname');
    if (savedNickname != null && savedNickname.isNotEmpty) {
      setState(() {
        _currentNickname = savedNickname;
      });
    } else {
      // 닉네임이 없으면 설정 다이얼로그 표시
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNicknameDialog();
      });
    }
  }

  Future<void> _saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', nickname);
    setState(() {
      _currentNickname = nickname;
    });
  }

  Future<void> _showNicknameDialog() async {
    String? newNickname = _currentNickname;
    await showDialog<String>(
      context: context,
      barrierDismissible: false, // 사용자가 다이얼로그 밖을 탭하여 닫을 수 없음
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('닉네임 설정'),
          content: TextField(
            onChanged: (value) {
              newNickname = value;
            },
            controller: TextEditingController(text: _currentNickname),
            decoration: const InputDecoration(hintText: '닉네임을 입력하세요'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('저장'),
              onPressed: () {
                if (newNickname != null && newNickname!.trim().isNotEmpty) {
                  _saveNickname(newNickname!);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('닉네임을 입력해주세요.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent) {
      if (!_showScrollToBottomButton) {
        setState(() {
          _showScrollToBottomButton = true;
        });
      }
    } else {
      if (_showScrollToBottomButton) {
        setState(() {
          _showScrollToBottomButton = false;
        });
      }
    }
  }

  void _onMessageChanged() {
    setState(() {
      _isMessageEmpty = _messageController.text.trim().isEmpty;
    });
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  String _formatTimestamp(String timestamp) {
    final DateTime messageTime = DateTime.parse(timestamp);
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = DateTime(now.year, now.month, now.day - 1);

    if (messageTime.isAfter(today)) {
      return DateFormat('a h:mm', 'ko-KR').format(messageTime); // 오늘 오전/오후 0:00
    } else if (messageTime.isAfter(yesterday)) {
      return DateFormat(
        '어제 a h:mm',
        'ko_KR',
      ).format(messageTime); // 어제 오전/오후 0:00
    } else {
      return DateFormat(
        'yyyy년 M월 d일 a h:mm',
        'ko_KR',
      ).format(messageTime); // 2025년 7월 1일 오전/오후 0:00
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    // if (content.isEmpty) return; // 이제 버튼 비활성화로 처리되므로 필요 없음

    try {
      await _supabase.from('messages').insert({
        'content': content,
        'sender': _currentNickname, // 설정된 닉네임 사용
        'local_user_id': _myLocalUserId, // 로컬 고유 ID 저장
      });
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메시지 전송에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('실시간 채팅'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _showNicknameDialog,
            tooltip: '닉네임 설정',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('에러: \${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;

                // 초기 로드 시 최신 메시지로 스크롤
                if (_isInitialLoad && messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                    setState(() {
                      _isInitialLoad = false;
                    });
                  });
                }

                // 새 메시지 도착 시 자동 스크롤 로직
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients &&
                      _scrollController.position.pixels >=
                          _scrollController.position.maxScrollExtent - 100) {
                    // 100 픽셀 이내면 맨 아래로 간주
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe =
                        msg['local_user_id'] ==
                        _myLocalUserId; // local_user_id로 나를 식별
                    final sender = msg['sender'] ?? '';
                    final content = msg['content'] ?? '';
                    final createdAt = msg['created_at'] != null
                        ? _formatTimestamp(msg['created_at'] as String)
                        : '';
                    return ChatMessage(
                      content: content,
                      sender: sender,
                      createdAt: createdAt,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter) {
                        final Set<LogicalKeyboardKey> pressed =
                            HardwareKeyboard.instance.logicalKeysPressed;

                        final bool isControlPressed =
                            pressed.contains(LogicalKeyboardKey.controlLeft) ||
                            pressed.contains(LogicalKeyboardKey.controlRight);
                        final bool isShiftPressed =
                            pressed.contains(LogicalKeyboardKey.shiftLeft) ||
                            pressed.contains(LogicalKeyboardKey.shiftRight);

                        if (isControlPressed || isShiftPressed) {
                          // CTRL + ENTER 또는 SHIFT + ENTER: 개행 처리
                          final text = _messageController.text;
                          final selection = _messageController.selection;
                          final newText = text.replaceRange(
                            selection.start,
                            selection.end,
                            '\n',
                          );
                          _messageController.value = _messageController.value
                              .copyWith(
                                text: newText,
                                selection: TextSelection.collapsed(
                                  offset: selection.start + 1,
                                ),
                              );
                          return KeyEventResult
                              .handled; // 이벤트 처리 완료, TextField의 기본 동작 막음
                        } else {
                          // ENTER만 눌렀을 때: 메시지 전송 (비어있지 않은 경우)
                          if (_messageController.text.trim().isNotEmpty) {
                            _sendMessage();
                          } else {}
                          return KeyEventResult
                              .handled; // 이벤트 처리 완료, TextField의 기본 개행 막음
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: '메시지를 입력하세요',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      keyboardType: TextInputType.multiline,
                      onTapOutside: (event) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isMessageEmpty ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _showScrollToBottomButton
          ? FloatingActionButton(
              onPressed: _scrollToBottom,
              child: const Icon(Icons.arrow_downward),
            )
          : null,
    );
  }
}
