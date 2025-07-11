import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/chat_message.dart';
import 'package:my_chat_app/models/message.dart';
import 'package:my_chat_app/models/theme_mode_provider.dart';
import 'package:my_chat_app/providers/chat_provider.dart';

import 'package:my_chat_app/utils/error_utils.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

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
    try {
      await chatProvider.sendMessage(_messageController.text);
      if (!mounted) return;
      _messageController.clear();
      FocusScope.of(context).unfocus(); // 키보드 닫기
    } catch (e, s) {
      if (mounted) showErrorSnackBar(context, e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeModeProvider = context.watch<ThemeModeProvider>();

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
                if (!chatProvider.isInitialized) {
                  return const Center(child: CircularProgressIndicator());
                }
                return StreamBuilder<List<Message>>(
                  stream: chatProvider.messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      // Use error_utils to show a SnackBar and log the error
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showErrorMessage(
                          context,
                          '실시간 메시지 로딩 중 오류 발생: ${snapshot.error}',
                        );
                      });
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('메시지를 불러오는 데 실패했습니다.'),
                            const SizedBox(height: UIConstants.spacingMedium),
                            ElevatedButton(
                              onPressed: () {
                                chatProvider
                                    .initialize(); // Re-initialize the stream
                              },
                              child: const Text('재시도'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (!snapshot.hasData ||
                        chatProvider.myLocalUserId == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data!;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_scrollController.hasClients) return;
                      // 사용자가 수동으로 스크롤 중이 아닐 때만 자동 스크롤
                      if (_scrollController.position.userScrollDirection ==
                              ScrollDirection.idle &&
                          (_isInitialLoad ||
                              _scrollController.position.pixels >=
                                  _scrollController.position.maxScrollExtent -
                                      100)) {
                        _scrollToBottom();
                        setState(() => _isInitialLoad = false);
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
            padding: const EdgeInsets.all(UIConstants.spacingMedium),
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
                          horizontal: UIConstants.messageInputHorizontalPadding,
                          vertical: UIConstants.messageInputVerticalPadding,
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
