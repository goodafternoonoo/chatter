import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard 사용을 위한 임포트
import 'package:intl/intl.dart';
import 'package:my_chat_app/utils/toast_utils.dart';
import 'models/message.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.message,
    required this.isMe,
    required this.myLocalUserId,
    required this.senderNickname, // senderNickname 추가
    this.avatarUrl, // avatarUrl 추가
    this.onDelete, // onDelete 콜백 추가
  });

  final Message message;
  final bool isMe;
  final String myLocalUserId;
  final String senderNickname; // senderNickname 필드 추가
  final String? avatarUrl; // avatarUrl 필드 추가
  final VoidCallback? onDelete; // onDelete 콜백 필드 추가

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (timestamp.isAfter(today)) {
      return DateFormat('a h:mm', 'ko-KR').format(timestamp);
    } else if (timestamp.isAfter(yesterday)) {
      return DateFormat('어제 a h:mm', 'ko-KR').format(timestamp);
    } else {
      return DateFormat('yyyy년 M월 d일 a h:mm', 'ko-KR').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = _formatTimestamp(message.createdAt);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: UIConstants.spacingSmall,
        horizontal: UIConstants.spacingMedium,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: UIConstants.avatarRadius,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              backgroundColor: Colors.grey[400],
              child: avatarUrl == null
                  ? Text(
                      senderNickname.isNotEmpty ? senderNickname[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: UIConstants.spacingMedium),
          ],
          if (isMe) // 내가 보낸 메시지일 때만 읽음/안읽음 표시
            Padding(
              padding: const EdgeInsets.only(
                right: UIConstants.spacingSmall,
                bottom: UIConstants.spacingSmall / 2,
              ), // 말풍선과의 간격 및 하단 정렬
              child: Text(
                message.readBy.any((id) => id != myLocalUserId)
                    ? '읽음'
                    : '1', // 읽음/안읽음 표시
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.primary, // 눈에 띄는 색상으로 변경
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.copy),
                            title: const Text('복사'),
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: message.content));
                              Navigator.pop(context);
                              ToastUtils.showToast(context, '메시지가 복사되었습니다.');
                            },
                          ),
                          if (isMe && onDelete != null) // 내가 보낸 메시지일 때만 삭제 옵션 제공
                            ListTile(
                              leading: const Icon(Icons.delete),
                              title: const Text('삭제'),
                              onTap: () {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('메시지 삭제'),
                                    content: const Text('이 메시지를 삭제하시겠습니까?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('취소'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          onDelete!();
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('삭제'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: UIConstants.chatBubbleVerticalPadding,
                  horizontal: UIConstants.chatBubbleHorizontalPadding,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(
                      UIConstants.borderRadiusChatBubble,
                    ),
                    topRight: const Radius.circular(
                      UIConstants.borderRadiusChatBubble,
                    ),
                    bottomLeft: isMe
                        ? const Radius.circular(
                            UIConstants.borderRadiusChatBubble,
                          )
                        : const Radius.circular(
                            UIConstants.borderRadiusChatBubbleSmall,
                          ),
                    bottomRight: isMe
                        ? const Radius.circular(
                            UIConstants.borderRadiusChatBubbleSmall,
                          )
                        : const Radius.circular(
                            UIConstants.borderRadiusChatBubble,
                          ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.shadow.withAlpha(25), // withOpacity(0.1)
                      blurRadius: UIConstants.spacingSmall,
                      offset: const Offset(0, UIConstants.spacingSmall / 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          senderNickname,
                          style: Theme.of(context).textTheme.labelMedium!
                              .copyWith(
                                color: isMe
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: UIConstants.spacingMedium),
                        Text(
                          createdAt,
                          style: Theme.of(context).textTheme.labelSmall!
                              .copyWith(
                                color: isMe
                                    ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withAlpha(178) // withOpacity(0.7)
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withAlpha(178), // withOpacity(0.7)
                              ),
                        ),
                      ],
                    ),
                    if (message.isDeleted) // 메시지가 삭제되었을 경우
                      Padding(
                        padding: EdgeInsets.only(top: UIConstants.spacingSmall),
                        child: Text(
                          '삭제된 메시지입니다.',
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withAlpha((0.6 * 255).round()),
                              ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          // 메시지가 삭제되지 않았을 경우 기존 내용 표시
                          if (message.imageUrl != null) // 이미지 URL이 있는 경우 이미지 표시
                            Padding(
                              padding: const EdgeInsets.only(
                                top: UIConstants.spacingSmall,
                                bottom: UIConstants.spacingSmall,
                              ),
                              child: Image.network(
                                message.imageUrl!,
                                width: 200, // 이미지 너비 제한
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text('이미지 로드 실패');
                                },
                              ),
                            ),
                          if (message
                              .content
                              .isNotEmpty) // 메시지 내용이 있는 경우 텍스트 표시
                            Padding(
                              padding: EdgeInsets.only(
                                top: message.imageUrl != null
                                    ? 0
                                    : UIConstants.spacingSmall,
                              ), // 이미지와 텍스트 간 간격 조절
                              child: Text(
                                message.content,
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(
                                      color: isMe
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: UIConstants.spacingMedium),
            CircleAvatar(
              radius: UIConstants.avatarRadius,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: avatarUrl == null
                  ? Text(
                      senderNickname.isNotEmpty ? senderNickname[0] : '?',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
