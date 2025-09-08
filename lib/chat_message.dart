import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard 사용을 위한 임포트
import 'package:intl/intl.dart';
import 'package:my_chat_app/utils/toast_utils.dart';
import 'models/message.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

/// 단일 채팅 메시지를 표시하는 위젯입니다.
///
/// 아바타, 닉네임, 메시지 내용(텍스트/이미지), 보낸 시간, 읽음 상태 등을 포함하는
/// 하나의 말풍선을 구성합니다. 길게 눌러 복사 또는 삭제(내 메시지인 경우)할 수 있습니다.
class ChatMessage extends StatelessWidget {
  /// 표시할 메시지 데이터입니다.
  final Message message;

  /// 이 메시지가 현재 사용자의 메시지인지 여부입니다.
  final bool isMe;

  /// 현재 사용자의 로컬 ID입니다.
  final String? myLocalUserId;

  /// 메시지를 보낸 사람의 닉네임입니다.
  final String senderNickname;

  /// 보낸 사람의 아바타 이미지 URL입니다.
  final String? avatarUrl;

  /// 보낸 사람의 온라인 상태입니다.
  final bool isOnline;

  /// 보낸 사람의 마지막 접속 시간입니다.
  final DateTime? lastSeen;

  /// 이 메시지를 삭제할 때 호출될 콜백 함수입니다. (내 메시지인 경우에만 제공)
  final VoidCallback? onDelete;

  /// {@template chat_message}
  /// `ChatMessage` 위젯을 생성합니다.
  /// {@endtemplate}
  const ChatMessage({
    super.key,
    required this.message,
    required this.isMe,
    this.myLocalUserId,
    required this.senderNickname,
    this.avatarUrl,
    required this.isOnline,
    this.lastSeen,
    this.onDelete,
  });

  /// `DateTime` 객체를 규칙에 따라 가독성 있는 문자열로 포맷팅합니다.
  /// `DateTime` 객체를 규칙에 따라 가독성 있는 문자열로 포맷팅합니다.
  ///
  /// - 오늘: '오전/오후 h:mm'
  /// - 어제: '어제 오전/오후 h:mm'
  /// - 그 이전: 'yyyy년 M월 d일 a h:mm'
  ///
  /// [timestamp] 포맷팅할 `DateTime` 객체입니다.
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

    // isMe 값에 따라 좌/우 정렬
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: UIConstants.spacingSmall,
        horizontal: UIConstants.spacingMedium,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 상대방 메시지인 경우 왼쪽에 아바타 표시
          if (!isMe) ...[
            _buildAvatar(context),
            const SizedBox(width: UIConstants.spacingSmall),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 상대방 메시지인 경우 닉네임 표시
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(
                        left: UIConstants.spacingSmall,
                        bottom: UIConstants.spacingSmall / 2),
                    child: Text(
                      senderNickname,
                      style: textTheme.labelMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                // 길게 눌렀을 때 복사/삭제 메뉴를 표시하기 위한 GestureDetector
                GestureDetector(
                  onLongPress: () => _showContextMenu(context),
                  child: _buildMessageBubble(context, colorScheme, textTheme),
                ),
                // 메시지 하단에 시간 및 읽음 상태 표시
                Padding(
                  padding: const EdgeInsets.only(top: UIConstants.spacingSmall),
                  child: Row(
                    mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      // 내 메시지이고 상대방이 읽었을 경우 '읽음' 표시
                      if (isMe &&
                          myLocalUserId != null &&
                          message.readBy.any((id) => id != myLocalUserId!))
                        Text(
                          '읽음',
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(width: UIConstants.spacingSmall),
                      Text(
                        createdAt,
                        style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withAlpha(178)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 내 메시지인 경우 오른쪽에 아바타 표시
          if (isMe) ...[
            const SizedBox(width: UIConstants.spacingSmall),
            _buildAvatar(context),
          ],
        ],
      ),
    );
  }

  /// 사용자 아바타를 생성하는 위젯입니다.
  ///
  /// 온라인 상태일 경우 초록색 점으로 표시합니다.
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
          backgroundColor:
              isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          child: avatarUrl == null
              ? Text(
                  senderNickname.isNotEmpty ? senderNickname[0] : '?',
                  style: textTheme.labelLarge?.copyWith(
                    color: isMe
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
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
                border:
                    Border.all(color: Theme.of(context).canvasColor, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  /// 메시지 말풍선을 생성하는 위젯입니다.
  ///
  /// 메시지 종류(텍스트, 이미지, 삭제됨)에 따라 다른 내용을 표시합니다.
  Widget _buildMessageBubble(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: UIConstants.chatBubbleVerticalPadding,
        horizontal: UIConstants.chatBubbleHorizontalPadding,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(UIConstants.borderRadiusChatBubble),
          topRight: const Radius.circular(UIConstants.borderRadiusChatBubble),
          bottomLeft: isMe
              ? const Radius.circular(UIConstants.borderRadiusChatBubble)
              : const Radius.circular(UIConstants.borderRadiusChatBubbleSmall),
          bottomRight: isMe
              ? const Radius.circular(UIConstants.borderRadiusChatBubbleSmall)
              : const Radius.circular(UIConstants.borderRadiusChatBubble),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(25),
            blurRadius: UIConstants.spacingSmall,
            offset: const Offset(0, UIConstants.spacingSmall / 2),
          ),
        ],
      ),
      child: _buildMessageContent(colorScheme, textTheme),
    );
  }

  /// 메시지 말풍선 내부의 실제 내용을 생성합니다.
  Widget _buildMessageContent(ColorScheme colorScheme, TextTheme textTheme) {
    if (message.isDeleted) {
      return Text(
        '삭제된 메시지입니다.',
        style: textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: colorScheme.onSurfaceVariant.withAlpha(153),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.imageUrl != null)
          Padding(
            padding: const EdgeInsets.only(bottom: UIConstants.spacingSmall),
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
              errorBuilder: (context, error, stackTrace) =>
                  const Text('이미지 로드 실패'),
            ),
          ),
        if (message.content.isNotEmpty)
          Text(
            message.content,
            style: textTheme.bodyMedium?.copyWith(
              color:
                  isMe ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
            ),
          ),
      ],
    );
  }

  /// 메시지를 길게 눌렀을 때 표시될 컨텍스트 메뉴(바텀 시트)입니다.
  void _showContextMenu(BuildContext context) {
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
                    _showDeleteConfirmationDialog(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// 메시지 삭제 전 사용자에게 확인을 받는 다이얼로그입니다.
  void _showDeleteConfirmationDialog(BuildContext context) {
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
  }
}