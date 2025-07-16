
class Message {
  final String id;
  final String content;
  final String localUserId;
  final DateTime createdAt;
  final List<String> readBy; // read_by 필드 추가
  final String? imageUrl; // image_url 필드 추가

  Message({
    required this.id,
    required this.content,
    required this.localUserId,
    required this.createdAt,
    required this.readBy, // read_by 필드 추가
    this.imageUrl, // image_url 필드 추가
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      localUserId: json['local_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      readBy: (json['read_by'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(), // read_by 파싱
      imageUrl: json['image_url'] as String?, // image_url 파싱
    );
  }
}
