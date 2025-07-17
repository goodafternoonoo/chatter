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
    this.myLocalUserId,
    required this.senderNickname, // senderNickname 추가
    this.avatarUrl, // avatarUrl 추가
    required this.isOnline, // isOnline 추가
    this.lastSeen, // lastSeen 추가
    this.onDelete, // onDelete 콜백 추가
  });

  final Message message;
  final bool isMe;
  final String? myLocalUserId;
  final String senderNickname; // senderNickname 필드 추가
  final String? avatarUrl; // avatarUrl 필드 추가
  final bool isOnline; // isOnline 필드 추가
  final DateTime? lastSeen; // lastSeen 필드 추가
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: UIConstants.spacingSmall,
        horizontal: UIConstants.spacingMedium,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(context),
            const SizedBox(width: UIConstants.spacingSmall),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: UIConstants.spacingSmall, bottom: UIConstants.spacingSmall / 2),
                    child: Text(
                      senderNickname,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                GestureDetector(
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
                              if (isMe && onDelete != null)
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
                      color: isMe ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(UIConstants.borderRadiusChatBubble),
                        topRight: Radius.circular(UIConstants.borderRadiusChatBubble),
                        bottomLeft: isMe
                            ? Radius.circular(UIConstants.borderRadiusChatBubble)
                            : Radius.circular(UIConstants.borderRadiusChatBubbleSmall),
                        bottomRight: isMe
                            ? Radius.circular(UIConstants.borderRadiusChatBubbleSmall)
                            : Radius.circular(UIConstants.borderRadiusChatBubble),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withAlpha(25),
                          blurRadius: UIConstants.spacingSmall,
                          offset: const Offset(0, UIConstants.spacingSmall / 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.isDeleted)
                          Text(
                            '삭제된 메시지입니다.',
                            style: textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: colorScheme.onSurfaceVariant.withAlpha(153),
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message.imageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: UIConstants.spacingSmall,
                                  ),
                                  child: Image.network(
                                    message.imageUrl!,
                                    width: 200,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Text('이미지 로드 실패');
                                    },
                                  ),
                                ),
                              if (message.content.isNotEmpty)
                                Text(
                                  message.content,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: isMe ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
                  child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (isMe && myLocalUserId != null)
                        Text(
                          message.readBy.any((id) => id != myLocalUserId!) ? '읽음' : '읽지 않음',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(width: UIConstants.spacingSmall),
                      Text(
                        createdAt,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withAlpha(178),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: UIConstants.spacingSmall),
            _buildAvatar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (senderNickname == '탈퇴한 사용자') {
      return CircleAvatar(
        radius: UIConstants.avatarRadius,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.person_off, color: colorScheme.onSurfaceVariant),
      );
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: UIConstants.avatarRadius,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          backgroundColor: isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          child: avatarUrl == null
              ? Text(
                  senderNickname.isNotEmpty ? senderNickname[0] : '?',
                  style: textTheme.labelLarge?.copyWith(
                    color: isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}