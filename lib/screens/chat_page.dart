import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/chat_provider.dart';
import 'package:my_chat_app/utils/error_utils.dart';
import 'package:my_chat_app/constants/ui_constants.dart';
import 'package:my_chat_app/mixins/scroll_controller_mixin.dart';
import 'package:my_chat_app/widgets/chat/chat_app_bar.dart';
import 'package:my_chat_app/widgets/chat/search_field.dart';
import 'package:my_chat_app/widgets/chat/message_list.dart';
import 'package:my_chat_app/widgets/chat/message_input.dart';
import 'package:my_chat_app/models/theme_mode_provider.dart';

class ChatPage extends StatefulWidget {
  final String roomId;

  const ChatPage({super.key, required this.roomId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with ScrollControllerMixin<ChatPage>, WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _focusNode = FocusNode();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _isMessageEmpty = true;
  bool _showEmojiPicker = false;
  bool _showSearchField = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(_onMessageChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    });
    _searchController.addListener(() {
      setState(() {});
    });
    scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  void _markMessagesAsRead() {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.markAllMessagesAsRead();
  }

  void _onScroll() {
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
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
      _focusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    } catch (e, s) {
      if (mounted) showErrorSnackBar(context, e, s);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      if (!mounted) return;
      final chatProvider = context.read<ChatProvider>();
      try {
        final imageUrl = await chatProvider.uploadImage(image);
        if (!mounted) return;
        await chatProvider.sendMessage('', imageUrl: imageUrl);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom();
        });
      } catch (e, s) {
        if (mounted) {
          showErrorSnackBar(context, e, s);
        }
      }
    }
  }

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

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        FocusScope.of(context).unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeModeProvider = context.watch<ThemeModeProvider>();

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
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          if (_showSearchField) {
            _toggleSearch();
            _focusNode.requestFocus();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: ChatAppBar(
          showSearchField: _showSearchField,
          onToggleSearch: _toggleSearch,
          onToggleTheme: themeModeProvider.toggleTheme,
        ),
        body: Stack(
          children: [
            Column(
              children: [
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
            if (showScrollToBottomButton)
              Positioned(
                bottom: kToolbarHeight + UIConstants.spacingMedium,
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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: null,
      ),
    );
  }
}