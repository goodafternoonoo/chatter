import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'
    as emoji_picker_flutter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/chat_message.dart';
import 'package:my_chat_app/models/theme_mode_provider.dart';
import 'package:my_chat_app/providers/chat_provider.dart';
import 'package:my_chat_app/models/profile.dart'; // Profile 모델 임포트
import 'package:my_chat_app/providers/profile_provider.dart'; // ProfileProvider 임포트
import 'package:my_chat_app/utils/error_utils.dart';
import 'package:my_chat_app/constants/ui_constants.dart';
import 'package:my_chat_app/mixins/scroll_controller_mixin.dart';
import 'package:go_router/go_router.dart';

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
  final _searchController = TextEditingController(); // 검색 컨트롤러 추가
  final _searchFocusNode = FocusNode(); // 검색 포커스 노드 추가

  bool _isMessageEmpty = true;
  bool _showEmojiPicker = false; // 이모티콘 선택기 표시 여부
  bool _showSearchField = false; // 검색 필드 표시 여부

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmojiPicker = false; // 키보드가 올라오면 이모티콘 선택기 숨김
        });
      }
    });
    _searchController.addListener(() {
      // 검색어 변경 시 로직 추가 (예: 검색 실행)
    });
    // 스크롤 리스너 추가
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _focusNode.dispose(); // FocusNode 해제
    _searchController.dispose(); // 검색 컨트롤러 해제
    _searchFocusNode.dispose(); // 검색 포커스 노드 해제
    // 스크롤 리스너 제거
    scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      // 스크롤이 최상단에 도달했을 때 (reverse: true 이므로 maxScrollExtent가 최상단)
      final chatProvider = context.read<ChatProvider>();
      if (chatProvider.hasMoreMessages && !chatProvider.isLoadingMore) {
        chatProvider.loadMoreMessages();
      }
    }
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

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      if (!mounted) return; // 추가된 부분
      final chatProvider = context.read<ChatProvider>();
      try {
        final imageUrl = await chatProvider.uploadImage(image);
        if (!mounted) return;
        await chatProvider.sendMessage(
          '',
          imageUrl: imageUrl,
        ); // 이미지 URL을 메시지로 전송
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom(); // 메시지 전송 후 최하단으로 스크롤
        });
      } catch (e, s) {
        if (mounted) {
          showErrorSnackBar(context, e, s);
        }
      }
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
              _showSearchField ? Icons.close : Icons.search, // 검색 필드 토글 아이콘
            ),
            onPressed: () {
              setState(() {
                _showSearchField = !_showSearchField;
                if (!_showSearchField) {
                  _searchController.clear(); // 검색 필드 닫을 때 검색어 초기화
                } else {
                  _searchFocusNode.requestFocus(); // 검색 필드 열 때 포커스
                }
              });
            },
            tooltip: '메시지 검색',
          ),
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
      body: Stack(
        children: [
          Column(
            children: [
              if (_showSearchField) // 검색 필드 표시
                Padding(
                  padding: const EdgeInsets.all(UIConstants.spacingMedium),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: '검색어를 입력하세요',
                            border: const OutlineInputBorder(), // 테두리 추가
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            ),
                          ),
                          onSubmitted: (value) {
                            final chatProvider = context.read<ChatProvider>();
                            chatProvider.searchMessages(value);
                          },
                        ),
                      ),
                      const SizedBox(width: UIConstants.spacingSmall),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          final chatProvider = context.read<ChatProvider>();
                          chatProvider.searchMessages(_searchController.text);
                        },
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final profileProvider = context
                        .watch<ProfileProvider>(); // ProfileProvider watch

                    if (chatProvider.error != null) {
                      return Center(child: Text('오류: ${chatProvider.error}'));
                    }
                    if (!chatProvider.isInitialized ||
                        (chatProvider.messages.isEmpty &&
                            !chatProvider.isLoadingMore)) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = chatProvider.messages;
                    final searchResults =
                        chatProvider.searchResults; // 검색 결과 가져오기

                    // 검색 필드가 활성화되어 있고 검색 결과가 있을 경우 검색 결과 표시
                    if (_showSearchField && searchResults.isNotEmpty) {
                      return ListView.builder(
                        key: const ValueKey('searchListView'),
                        controller: scrollController, // 검색 결과도 스크롤 가능하도록
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final message = searchResults[index];
                          final isMe =
                              message.localUserId ==
                              profileProvider.currentLocalUserId;

                          return FutureBuilder<Profile?>(
                            future: profileProvider.getProfileById(
                              message.localUserId,
                            ),
                            builder: (context, profileSnapshot) {
                              final Profile? senderProfile =
                                  profileSnapshot.data;
                              return ChatMessage(
                                message: message,
                                isMe: isMe,
                                myLocalUserId:
                                    profileProvider.currentLocalUserId!,
                                senderNickname:
                                    senderProfile?.nickname ?? '알 수 없음',
                                avatarUrl: isMe
                                    ? profileProvider.currentProfile?.avatarUrl
                                    : senderProfile?.avatarUrl,
                                isOnline: senderProfile?.isOnline ?? false,
                                lastSeen: senderProfile?.lastSeen,
                                onDelete: isMe && !message.isDeleted
                                    ? () =>
                                          chatProvider.deleteMessage(message.id)
                                    : null,
                              );
                            },
                          );
                        },
                      );
                    } else if (_showSearchField &&
                        searchResults.isEmpty &&
                        _searchController.text.isNotEmpty) {
                      // 검색 필드가 활성화되어 있고 검색 결과가 없으며 검색어가 입력된 경우
                      return const Center(child: Text('검색 결과가 없습니다.'));
                    } else {
                      // 일반 메시지 목록 표시
                      return ListView.builder(
                        key: const ValueKey('chatListView'),
                        controller: scrollController,
                        reverse: true,
                        itemCount:
                            messages.length +
                            (chatProvider.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (chatProvider.isLoadingMore &&
                              index == messages.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final message = messages[index];
                          final isMe =
                              message.localUserId ==
                              profileProvider.currentLocalUserId;

                          if (!isMe &&
                              !message.readBy.contains(
                                profileProvider.currentLocalUserId,
                              )) {
                            chatProvider.markMessageAsRead(message.id);
                          }

                          return FutureBuilder<Profile?>(
                            future: profileProvider.getProfileById(
                              message.localUserId,
                            ),
                            builder: (context, profileSnapshot) {
                              final Profile? senderProfile =
                                  profileSnapshot.data;
                              return ChatMessage(
                                message: message,
                                isMe: isMe,
                                myLocalUserId:
                                    profileProvider.currentLocalUserId!,
                                senderNickname:
                                    senderProfile?.nickname ?? '알 수 없음',
                                avatarUrl: isMe
                                    ? profileProvider.currentProfile?.avatarUrl
                                    : senderProfile?.avatarUrl,
                                isOnline: senderProfile?.isOnline ?? false,
                                lastSeen: senderProfile?.lastSeen,
                                onDelete: isMe && !message.isDeleted
                                    ? () =>
                                          chatProvider.deleteMessage(message.id)
                                    : null,
                              );
                            },
                          );
                        },
                      );
                    }
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
                                pressed.contains(
                                  LogicalKeyboardKey.controlLeft,
                                ) ||
                                pressed.contains(
                                  LogicalKeyboardKey.controlRight,
                                ) ||
                                pressed.contains(
                                  LogicalKeyboardKey.shiftLeft,
                                ) ||
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
                              horizontal:
                                  UIConstants.messageInputHorizontalPadding,
                              vertical: UIConstants.messageInputVerticalPadding,
                            ),
                          ),
                          keyboardType: TextInputType.multiline,
                          onTapOutside: (event) =>
                              FocusScope.of(context).unfocus(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.image), // 이미지 첨부 버튼
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('갤러리에서 선택'),
                                    onTap: () {
                                      context.pop();
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                  if (foundation.defaultTargetPlatform !=
                                      TargetPlatform
                                          .windows) // Windows가 아닐 때만 카메라 옵션 표시
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt),
                                      title: const Text('카메라로 촬영'),
                                      onTap: () {
                                        context.pop();
                                        _pickImage(ImageSource.camera);
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _showEmojiPicker
                            ? Icons.keyboard
                            : Icons.emoji_emotions,
                      ),
                      onPressed: () {
                        setState(() {
                          _showEmojiPicker = !_showEmojiPicker;
                          if (_showEmojiPicker) {
                            FocusScope.of(
                              context,
                            ).unfocus(); // 이모티콘 선택기 표시 시 키보드 숨김
                          } else {
                            _focusNode.requestFocus(); // 이모티콘 선택기 숨김 시 키보드 표시
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isMessageEmpty ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
              Offstage(
                offstage: !_showEmojiPicker,
                child: SizedBox(
                  height: 250, // 이모티콘 선택기 높이
                  child: emoji_picker_flutter.EmojiPicker(
                    textEditingController: _messageController,
                    onEmojiSelected: (category, emoji) {
                      // 이모티콘이 선택되었을 때의 로직은 textEditingController가 처리
                    },
                    config: emoji_picker_flutter.Config(
                      height: 250,
                      checkPlatformCompatibility: true,
                      emojiViewConfig: emoji_picker_flutter.EmojiViewConfig(
                        emojiSizeMax:
                            28 *
                            (foundation.defaultTargetPlatform ==
                                    TargetPlatform.iOS
                                ? 1.20
                                : 1.0),
                      ),
                      skinToneConfig:
                          const emoji_picker_flutter.SkinToneConfig(),
                      categoryViewConfig:
                          emoji_picker_flutter.CategoryViewConfig(
                            initCategory: emoji_picker_flutter.Category.RECENT,
                            indicatorColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            iconColor: Colors.grey,
                            iconColorSelected: Theme.of(
                              context,
                            ).colorScheme.primary,
                            backspaceColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                      bottomActionBarConfig:
                          const emoji_picker_flutter.BottomActionBarConfig(),
                      searchViewConfig:
                          const emoji_picker_flutter.SearchViewConfig(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showScrollToBottomButton)
            Positioned(
              bottom:
                  kToolbarHeight + UIConstants.spacingMedium, // 메시지 입력 필드 위에 위치
              left: 0.0, // 왼쪽 정렬
              right: 0.0, // 오른쪽 정렬
              child: Center(
                child: FloatingActionButton(
                  onPressed: scrollToBottom,
                  child: const Icon(Icons.arrow_downward),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: null, // Stack에서 직접 관리하므로 null로 설정
    );
  }
}
