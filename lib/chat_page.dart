import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final String myName = '익명'; // 임시 내 닉네임
  final _scrollController = ScrollController();
  bool _showScrollToBottomButton = false;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _messagesStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => data);

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
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

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await _supabase.from('messages').insert({
        'content': content,
        'sender': '익명', // 필요시 사용자 이름으로 변경
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
      appBar: AppBar(title: const Text('실시간 채팅')),
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
                    final isMe = msg['sender'] == myName;
                    final sender = msg['sender'] ?? '';
                    final content = msg['content'] ?? '';
                    final createdAt = msg['created_at'] != null
                        ? msg['created_at'].toString().substring(0, 16)
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
                        final bool hasModifier =
                            pressed.contains(LogicalKeyboardKey.control) ||
                            pressed.contains(LogicalKeyboardKey.shift) ||
                            pressed.contains(LogicalKeyboardKey.alt) ||
                            pressed.contains(LogicalKeyboardKey.meta);

                        if (!hasModifier) {
                          _sendMessage();
                          return KeyEventResult.handled;
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
                      textInputAction: TextInputAction.newline,
                      onTapOutside: (event) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
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
