import 'package:flutter/foundation.dart' as foundation;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

/// 채팅 페이지 하단에 위치하는 메시지 입력 컴포넌트입니다.
///
/// 텍스트 입력, 이미지 전송, 이모지 선택, 키보드 단축키(메시지 전송/줄바꿈) 기능을 포함합니다.
class MessageInput extends StatefulWidget {
  /// 텍스트 필드를 제어하는 컨트롤러입니다.
  final TextEditingController messageController;

  /// 텍스트 필드의 포커스를 관리하는 노드입니다.
  final FocusNode focusNode;

  /// 메시지 입력창이 비어있는지 여부입니다.
  final bool isMessageEmpty;

  /// 이모지 피커의 표시 여부입니다.
  final bool showEmojiPicker;

  /// 메시지 전송 버튼을 눌렀을 때 호출되는 콜백입니다.
  final VoidCallback onSendMessage;

  /// 이미지 소스(갤러리/카메라)를 선택했을 때 호출되는 콜백입니다.
  final Function(ImageSource) onPickImage;

  /// 이모지 피커 표시/숨기기 버튼을 눌렀을 때 호출되는 콜백입니다.
  final VoidCallback onToggleEmojiPicker;

  /// {@template message_input}
  /// `MessageInput` 위젯을 생성합니다.
  /// {@endtemplate}
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
                // 이미지 선택 버튼
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
                              // Windows 에서는 카메라를 지원하지 않음
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
                // 이모지 피커 토글 버튼
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
                  // 키보드 단축키 처리를 위한 Focus 위젯
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter) {
                        // Ctrl 또는 Shift 키와 함께 Enter를 누르면 줄바꿈
                        final Set<LogicalKeyboardKey> pressed =
                            HardwareKeyboard.instance.logicalKeysPressed;
                        final bool isModifierPressed =
                            pressed.contains(LogicalKeyboardKey.controlLeft) ||
                                pressed.contains(LogicalKeyboardKey.controlRight) ||
                                pressed.contains(LogicalKeyboardKey.shiftLeft) ||
                                pressed.contains(LogicalKeyboardKey.shiftRight);

                        if (isModifierPressed) {
                          // 수동으로 줄바꿈 문자 삽입
                          final currentVal = widget.messageController.value;
                          final newText =
                              '${currentVal.text.substring(0, currentVal.selection.start)}\n${currentVal.text.substring(currentVal.selection.end)}';
                          widget.messageController.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(
                              offset: currentVal.selection.start + 1,
                            ),
                          );
                        } else {
                          // Enter만 누르면 메시지 전송
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
                // 메시지 전송 버튼
                IconButton(
                  icon: Icon(Icons.send, color: colorScheme.primary),
                  onPressed:
                      widget.isMessageEmpty ? null : widget.onSendMessage,
                ),
              ],
            ),
          ),
        ),
        // 이모지 피커
        Offstage(
          offstage: !widget.showEmojiPicker,
          child: SizedBox(
            height: 250,
            child: EmojiPicker(
              textEditingController: widget.messageController,
              onEmojiSelected: (category, emoji) {},
              config: Config(
                height: 250,
                checkPlatformCompatibility: true,
                locale: const Locale('ko'),
                viewOrderConfig: const ViewOrderConfig(),
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 28 *
                      (foundation.defaultTargetPlatform == TargetPlatform.iOS
                          ? 1.20
                          : 1.0),
                  backgroundColor: colorScheme.surfaceContainerHigh,
                ),
                skinToneConfig: const SkinToneConfig(),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  initCategory: Category.RECENT,
                  indicatorColor: colorScheme.primary,
                  iconColor: colorScheme.onSurfaceVariant,
                  iconColorSelected: colorScheme.primary,
                  backspaceColor: colorScheme.primary,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  buttonColor: colorScheme.primary,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  buttonIconColor: colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
