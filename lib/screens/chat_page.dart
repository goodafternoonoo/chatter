import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_chat_app/models/room.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/chat_provider.dart';
import 'package:my_chat_app/providers/room_provider.dart'; // RoomProvider 임포트
import 'package:my_chat_app/utils/error_utils.dart';
import 'package:my_chat_app/mixins/scroll_controller_mixin.dart';
import 'package:my_chat_app/widgets/common_app_bar.dart';
import 'package:my_chat_app/widgets/chat/search_field.dart';
import 'package:my_chat_app/widgets/chat/message_list.dart';
import 'package:my_chat_app/widgets/chat/message_input.dart';

/// 개별 채팅방 화면을 구성하는 페이지 위젯입니다.
///
/// `CommonAppBar`, `MessageList`, `MessageInput`, `SearchField` 등
/// 여러 재사용 위젯을 조합하여 채팅 인터페이스를 구현합니다.
/// 사용자의 입력 및 스크롤에 따라 상태를 관리하고 UI를 동적으로 변경합니다.
class ChatPage extends StatefulWidget {
  /// 현재 채팅방의 ID입니다.
  final String roomId;

  /// {@template chat_page}
  /// `ChatPage` 위젯을 생성합니다.
  /// {@endtemplate}
  const ChatPage({super.key, required this.roomId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with ScrollControllerMixin<ChatPage>, WidgetsBindingObserver {
  // 컨트롤러 및 포커스 노드
  final _messageController = TextEditingController();
  final _focusNode = FocusNode();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  // UI 상태 변수
  bool _isMessageEmpty = true;
  bool _showEmojiPicker = false;
  bool _showSearchField = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 리스너 등록
    _messageController.addListener(_onMessageChanged);
    _focusNode.addListener(_onFocusChanged);
    _searchController.addListener(() => setState(() {})); // 검색어 변경 시 UI 갱신
    scrollController.addListener(_onScroll);

    // 위젯 렌더링 후 초기 작업 수행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 컨트롤러 및 리스너 해제
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 다시 활성화될 때 메시지를 읽음 처리합니다.
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  /// 메시지 입력 필드에 포커스가 가면 이모지 피커를 숨깁니다.
  void _onFocusChanged() {
    if (_focusNode.hasFocus && _showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
    }
  }

  /// 현재 방의 모든 메시지를 읽음으로 표시합니다.
  void _markMessagesAsRead() {
    context.read<ChatProvider>().markAllMessagesAsRead();
  }

  /// 스크롤이 리스트의 끝(가장 오래된 메시지)에 도달하면 이전 메시지를 불러옵니다.
  void _onScroll() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      final chatProvider = context.read<ChatProvider>();
      if (chatProvider.hasMoreMessages && !chatProvider.isLoadingMore) {
        chatProvider.loadMoreMessages();
      }
    }
  }

  /// 메시지 입력 내용이 변경될 때마다 `_isMessageEmpty` 상태를 업데이트합니다.
  void _onMessageChanged() {
    setState(() => _isMessageEmpty = _messageController.text.trim().isEmpty);
  }

  /// 메시지를 전송합니다.
  Future<void> _sendMessage() async {
    try {
      await context.read<ChatProvider>().sendMessage(_messageController.text);
      if (!mounted) return;
      _messageController.clear();
      _focusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    } catch (e, s) {
      if (mounted) showErrorSnackBar(context, e, s);
    }
  }

  /// 갤러리 또는 카메라에서 이미지를 선택하여 전송합니다.
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await ImagePicker().pickImage(source: source);
    if (image == null) return;

    try {
      final chatProvider = context.read<ChatProvider>();
      final imageUrl = await chatProvider.uploadImage(image);
      if (!mounted) return;
      await chatProvider.sendMessage('', imageUrl: imageUrl);
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    } catch (e, s) {
      if (mounted) showErrorSnackBar(context, e, s);
    }
  }

  /// 검색 필드의 표시 여부를 토글합니다.
  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) {
        _searchController.clear();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  /// 이모지 피커의 표시 여부를 토글합니다.
  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        FocusScope.of(context).unfocus(); // 키보드 숨기기
      } else {
        _focusNode.requestFocus(); // 키보드 보이기
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 현재 방의 이름을 가져옵니다. 방이 삭제되는 등의 경우를 대비해 orElse로 기본값을 제공합니다.
    final roomName = context
        .watch<RoomProvider>()
        .rooms
        .firstWhere((room) => room.id == widget.roomId,
            orElse: () => Room(id: '', name: '채팅방', createdAt: DateTime.now()))
        .name;

    // 키보드 단축키(검색, 창 닫기)를 감지하기 위한 Focus 위젯
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyF &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _toggleSearch();
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          if (_showSearchField) {
            _toggleSearch();
            _focusNode.requestFocus();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: null, // 기본 AppBar는 사용하지 않음
        body: Stack(
          children: [
            Column(
              children: [
                CommonAppBar(
                  title: Text(roomName),
                  actions: [
                    IconButton(
                      icon: Icon(_showSearchField ? Icons.close : Icons.search),
                      onPressed: _toggleSearch,
                      tooltip: '메시지 검색 (Ctrl+F)',
                    ),
                  ],
                ),
                if (_showSearchField)
                  SearchField(
                    searchController: _searchController,
                    searchFocusNode: _searchFocusNode,
                  ),
                Expanded(
                  child: MessageList(
                    scrollController: scrollController,
                    showSearchField: _showSearchField,
                    searchText: _searchController.text,
                  ),
                ),
                MessageInput(
                  messageController: _messageController,
                  focusNode: _focusNode,
                  isMessageEmpty: _isMessageEmpty,
                  showEmojiPicker: _showEmojiPicker,
                  onSendMessage: _sendMessage,
                  onPickImage: _pickImage,
                  onToggleEmojiPicker: _toggleEmojiPicker,
                ),
              ],
            ),
            // "맨 아래로" 스크롤 버튼
            if (showScrollToBottomButton)
              Positioned(
                bottom: kToolbarHeight + 16.0,
                left: 0.0,
                right: 0.0,
                child: Center(
                  child: FloatingActionButton(
                    onPressed: scrollToBottom,
                    child: const Icon(Icons.arrow_downward),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
