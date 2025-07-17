class Room {
  final String id;
  final String name;
  final DateTime createdAt;
  int unreadCount; // 읽지 않은 메시지 수 추가

  Room({
    required this.id,
    required this.name,
    required this.createdAt,
    this.unreadCount = 0, // 기본값 0
  });

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      unreadCount: map['unread_count'] ?? 0, // unread_count 파싱, 없으면 0
    );
  }
}
