import 'package:flutter/foundation.dart' as foundation;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'
    as emoji_picker_flutter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController messageController;
  final FocusNode focusNode;
  final bool isMessageEmpty;
  final bool showEmojiPicker;
  final VoidCallback onSendMessage;
  final Function(ImageSource) onPickImage;
  final VoidCallback onToggleEmojiPicker;

  const MessageInput({
    super.key,
    required this.messageController,
    required this.focusNode,
    required this.isMessageEmpty,
    required this.showEmojiPicker,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onToggleEmojiPicker,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(UIConstants.spacingMedium),
          elevation: UIConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              UIConstants.borderRadiusCircular,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacingSmall,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: colorScheme.onSurfaceVariant),
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
                                  widget.onPickImage(ImageSource.gallery);
                                },
                              ),
                              if (foundation.defaultTargetPlatform !=
                                  TargetPlatform.windows)
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('카메라로 촬영'),
                                  onTap: () {
                                    context.pop();
                                    widget.onPickImage(ImageSource.camera);
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
                    widget.showEmojiPicker
                        ? Icons.keyboard
                        : Icons.emoji_emotions,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: widget.onToggleEmojiPicker,
                ),
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
                          final currentVal = widget.messageController.value;
                          final newText =
                              '${currentVal.text.substring(0, currentVal.selection.start)} ${currentVal.text.substring(currentVal.selection.end)}';
                          widget.messageController.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(
                              offset: currentVal.selection.start + 1,
                            ),
                          );
                        } else {
                          if (!widget.isMessageEmpty) widget.onSendMessage();
                        }
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: widget.messageController,
                      focusNode: widget.focusNode,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요',
                        contentPadding: const EdgeInsets.symmetric(
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
                  icon: Icon(Icons.send, color: colorScheme.primary),
                  onPressed: widget.isMessageEmpty
                      ? null
                      : widget.onSendMessage,
                ),
              ],
            ),
          ),
        ),
        Offstage(
          offstage: !widget.showEmojiPicker,
          child: SizedBox(
            height: 250,
            child: emoji_picker_flutter.EmojiPicker(
              textEditingController: widget.messageController,
              onEmojiSelected: (category, emoji) {},
              config: emoji_picker_flutter.Config(
                height: 250,
                checkPlatformCompatibility: true,
                emojiViewConfig: emoji_picker_flutter.EmojiViewConfig(
                  emojiSizeMax:
                      28 *
                      (foundation.defaultTargetPlatform == TargetPlatform.iOS
                          ? 1.20
                          : 1.0),
                ),
                skinToneConfig: const emoji_picker_flutter.SkinToneConfig(),
                categoryViewConfig: emoji_picker_flutter.CategoryViewConfig(
                  initCategory: emoji_picker_flutter.Category.RECENT,
                  indicatorColor: colorScheme.primary,
                  iconColor: colorScheme.onSurfaceVariant,
                  iconColorSelected: colorScheme.primary,
                  backspaceColor: colorScheme.primary,
                ),
                bottomActionBarConfig:
                    const emoji_picker_flutter.BottomActionBarConfig(),
                searchViewConfig: const emoji_picker_flutter.SearchViewConfig(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
