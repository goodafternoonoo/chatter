import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_chat_app/models/room.dart';
import 'package:intl/intl.dart'; // DateFormat 사용을 위한 임포트
import 'package:my_chat_app/constants/ui_constants.dart';

/// 채팅방 목록의 각 항목을 나타내는 위젯입니다.
///
/// 채팅방 이름, 마지막 메시지, 시간, 읽지 않은 메시지 수를 표시합니다.
/// 탭하면 해당 채팅방으로 이동하고, 길게 누르면 `onLongPress` 콜백을 실행합니다.
class RoomListItem extends StatelessWidget {
  /// 표시할 채팅방의 데이터 모델입니다.
  final Room room;

  /// 위젯을 길게 눌렀을 때 호출될 콜백 함수입니다. (예: 채팅방 삭제 메뉴 표시)
  final VoidCallback onLongPress;

  /// {@template room_list_item}
  /// `RoomListItem` 위젯을 생성합니다.
  /// {@endtemplate}
  const RoomListItem({super.key, required this.room, required this.onLongPress});

  /// `DateTime` 객체를 사용자의 가독성에 맞게 포맷팅합니다.
  ///
  /// - 오늘: '오전/오후 h:mm'
  /// - 어제: '어제 오전/오후 h:mm'
  /// - 그 이전: 'yyyy.MM.dd'
  ///
  /// [timestamp] 포맷팅할 `DateTime` 객체입니다. `null`이면 빈 문자열을 반환합니다.
  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (timestamp.isAfter(today)) {
      return DateFormat('a h:mm', 'ko-KR').format(timestamp);
    } else if (timestamp.isAfter(yesterday)) {
      return DateFormat('어제 a h:mm', 'ko-KR').format(timestamp);
    } else {
      return DateFormat('yyyy.MM.dd', 'ko-KR').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: UIConstants.paddingMedium,
          vertical: UIConstants.spacingSmall),
      child: InkWell(
        onTap: () {
          context.push('/chat/${room.id}');
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusCircular),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.paddingMedium),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (room.lastMessageContent != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: UIConstants.spacingSmall),
                        child: Text(
                          room.lastMessageContent!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (room.lastMessageCreatedAt != null)
                    Text(
                      _formatTimestamp(room.lastMessageCreatedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  if (room.unreadCount > 0)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: UIConstants.spacingSmall),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: UIConstants.paddingSmall,
                            vertical: UIConstants.spacingSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(
                              UIConstants.borderRadiusCircular),
                        ),
                        child: Text(
                          '${room.unreadCount}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
