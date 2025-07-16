class Message {
  final String id;
  final String content;
  final String localUserId;
  final DateTime createdAt;
  final List<String> readBy; // read_by 필드 추가
  final String? imageUrl; // image_url 필드 추가
  final bool isDeleted; // is_deleted 필드 추가

  Message({
    required this.id,
    required this.content,
    required this.localUserId,
    required this.createdAt,
    required this.readBy, // read_by 필드 추가
    this.imageUrl, // image_url 필드 추가
    this.isDeleted = false, // is_deleted 필드 추가 및 기본값 설정
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      localUserId: json['local_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      readBy: (json['read_by'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(), // read_by 파싱
      imageUrl: json['image_url'] as String?, // image_url 파싱
      isDeleted: json['is_deleted'] as bool? ?? false, // is_deleted 파싱
    );
  }
}
