
class Message {
  final String id;
  final String content;
  final String sender;
  final String localUserId;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.content,
    required this.sender,
    required this.localUserId,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      sender: json['sender'] as String,
      localUserId: json['local_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
