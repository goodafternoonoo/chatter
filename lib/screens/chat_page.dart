import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/chat_message.dart';
import 'package:my_chat_app/models/message.dart';
import 'package:my_chat_app/models/theme_mode_provider.dart';
import 'package:my_chat_app/providers/chat_provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _showScrollToBottomButton = false;
  bool _isInitialLoad = true;
  bool _isMessageEmpty = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    super.dispose();
  }

  // _onProviderInit method removed

  void _scrollListener() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent) {
      if (!_showScrollToBottomButton) {
        setState(() => _showScrollToBottomButton = true);
      }
    } else {
      if (_showScrollToBottomButton) {
        setState(() => _showScrollToBottomButton = false);
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

  Future<void> _sendMessage() async {
    final chatProvider = context.read<ChatProvider>();
    // Call ScaffoldMessenger.of(context) before the await
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    try {
      await chatProvider.sendMessage(_messageController.text);
      _messageController.clear();
    } catch (e) {
      // Use the captured messenger
      messenger.showSnackBar(
        SnackBar(
          content: const Text('메시지 전송에 실패했습니다.'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final themeModeProvider = context.watch<ThemeModeProvider>();
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('실시간 채팅'),
        actions: [
          IconButton(
            icon: Icon(
              themeModeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: themeModeProvider.toggleTheme,
            tooltip: '테마 전환',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.error != null) {
                  return Center(child: Text('오류: ${chatProvider.error}'));
                }
                if (!chatProvider.isInitialized || chatProvider.messagesStream == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return StreamBuilder<List<Message>>(
                  stream: chatProvider.messagesStream!,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('에러: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || chatProvider.myLocalUserId == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data!;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_scrollController.hasClients) return;
                      if (_isInitialLoad && messages.isNotEmpty) {
                        _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                        );
                        setState(() => _isInitialLoad = false);
                      } else if (_scrollController.position.pixels >=
                          _scrollController.position.maxScrollExtent - 100) {
                        _scrollToBottom();
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe =
                            message.localUserId == chatProvider.myLocalUserId;
                        return ChatMessage(message: message, isMe: isMe);
                      },
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
                        final bool isModifierPressed =
                            pressed.contains(LogicalKeyboardKey.controlLeft) ||
                                pressed.contains(LogicalKeyboardKey.controlRight) ||
                                pressed.contains(LogicalKeyboardKey.shiftLeft) ||
                                pressed.contains(LogicalKeyboardKey.shiftRight);

                        if (isModifierPressed) {
                          final currentVal = _messageController.value;
                          final newText =
                              '${currentVal.text.substring(0, currentVal.selection.start)}\n${currentVal.text.substring(currentVal.selection.end)}';
                          _messageController.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(
                              offset: currentVal.selection.start + 1,
                            ),
                          );
                        } else {
                          if (!_isMessageEmpty) _sendMessage();
                        }
                        return KeyEventResult.handled;
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
