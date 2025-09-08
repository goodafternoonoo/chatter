/// 채팅방을 나타내는 데이터 모델 클래스입니다.
///
/// 이 클래스는 Supabase의 `rooms` 테이블과 일대일로 매핑됩니다.
class Room {
  /// 채팅방의 고유 ID입니다. (UUID)
  final String id;

  /// 채팅방의 이름입니다.
  final String name;

  /// 채팅방이 생성된 시간입니다.
  final DateTime createdAt;

  /// 현재 사용자가 읽지 않은 메시지의 수입니다.
  ///
  /// 이 값은 실시간으로 업데이트될 수 있습니다.
  int unreadCount;

  /// 채팅방의 마지막 메시지 내용입니다.
  ///
  /// 채팅방 목록에서 미리보기로 사용됩니다.
  final String? lastMessageContent;

  /// 채팅방의 마지막 메시지가 생성된 시간입니다.
  final DateTime? lastMessageCreatedAt;

  /// {@template room}
  /// `Room` 클래스의 인스턴스를 생성합니다.
  /// {@endtemplate}
  Room({
    required this.id,
    required this.name,
    required this.createdAt,
    this.unreadCount = 0,
    this.lastMessageContent,
    this.lastMessageCreatedAt,
  });

  /// 맵에서 `Room` 인스턴스를 생성하는 팩토리 생성자입니다.
  ///
  /// Supabase에서 받은 데이터를 파싱하는 데 사용됩니다.
  /// 이 데이터는 `get_rooms_with_unread_count`와 같은 RPC 함수로부터 올 수 있습니다.
  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      unreadCount: map['unread_count'] ?? 0,
      lastMessageContent: map['last_message_content'],
      lastMessageCreatedAt: map['last_message_created_at'] != null
          ? DateTime.parse(map['last_message_created_at'])
          : null,
    );
  }
}
