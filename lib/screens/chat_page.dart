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
import 'package:my_chat_app/mixins/scroll_controller_mixin.dart';

class ChatPage extends StatefulWidget {
  final String roomId;

  const ChatPage({super.key, required this.roomId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with ScrollControllerMixin<ChatPage> {
  final _messageController = TextEditingController();
  final _focusNode = FocusNode(); // FocusNode 추가

  bool _isInitialLoad = true;
  bool _isMessageEmpty = true;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
    _focusNode.addListener(() {
      // 포커스 상태 변경 시 필요한 로직 추가 가능
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _focusNode.dispose(); // FocusNode 해제
    super.dispose();
  }

  void _onMessageChanged() {
    setState(() {
      _isMessageEmpty = _messageController.text.trim().isEmpty;
    });
  }

  Future<void> _sendMessage() async {
    final chatProvider = context.read<ChatProvider>();
    try {
      await chatProvider.sendMessage(_messageController.text);
      if (!mounted) return;
      _messageController.clear();
      _focusNode.requestFocus(); // 메시지 전송 후 포커스 유지
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom(); // 메시지 전송 후 최하단으로 스크롤
      });
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
                                chatProvider.initialize();
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

                    // 초기 로드 시 또는 메시지 추가 시 최하단으로 스크롤
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!scrollController.hasClients) return;

                      // 초기 로드 시 무조건 최하단으로 스크롤
                      if (_isInitialLoad) {
                        scrollToBottom();
                        setState(() => _isInitialLoad = false);
                      } else if (scrollController
                                  .position
                                  .userScrollDirection ==
                              ScrollDirection.idle &&
                          scrollController.position.pixels >=
                              scrollController.position.maxScrollExtent - 100) {
                        // 사용자가 최하단 근처에 있을 때만 자동 스크롤
                        scrollToBottom();
                      }
                    });

                    return ListView.builder(
                      key: const ValueKey('chatListView'), // 고유한 키 추가
                      controller: scrollController,
                      itemCount: messages.length,
                      addAutomaticKeepAlives: false, // 불필요한 최적화 비활성화
                      addRepaintBoundaries: false, // 불필요한 최적화 비활성화
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
                      focusNode: _focusNode, // focusNode 할당
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
      floatingActionButton: showScrollToBottomButton
          ? FloatingActionButton(
              onPressed: scrollToBottom,
              child: const Icon(Icons.arrow_downward),
            )
          : null,
    );
  }
}
