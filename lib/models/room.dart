class Room {
  final String id;
  final String name;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
