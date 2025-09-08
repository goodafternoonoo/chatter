/// 채팅 메시지를 나타내는 데이터 모델 클래스입니다.
///
/// 이 클래스는 Supabase의 `messages` 테이블과 일대일로 매핑됩니다.
class Message {
  /// 메시지의 고유 ID입니다. (UUID)
  final String id;

  /// 메시지의 텍스트 내용입니다.
  final String content;

  /// 메시지를 보낸 사용자의 로컬 ID입니다.
  ///
  /// `profiles` 테이블의 `id`를 참조합니다.
  final String? localUserId;

  /// 메시지가 생성된 시간입니다.
  final DateTime createdAt;

  /// 이 메시지를 읽은 사용자들의 ID 목록입니다.
  final List<String> readBy;

  /// 메시지에 포함된 이미지의 URL입니다.
  ///
  /// 텍스트 메시지의 경우 `null`일 수 있습니다.
  final String? imageUrl;

  /// 메시지가 논리적으로 삭제되었는지 여부를 나타냅니다.
  ///
  /// `true`이면 메시지 내용 대신 "삭제된 메시지입니다."와 같이 표시됩니다.
  final bool isDeleted;

  /// {@template message}
  /// `Message` 클래스의 인스턴스를 생성합니다.
  /// {@endtemplate}
  Message({
    required this.id,
    required this.content,
    required this.localUserId,
    required this.createdAt,
    required this.readBy,
    this.imageUrl,
    this.isDeleted = false,
  });

  /// JSON 맵에서 `Message` 인스턴스를 생성하는 팩토리 생성자입니다.
  ///
  /// Supabase에서 받은 데이터를 파싱하는 데 사용됩니다.
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      localUserId: json['local_user_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      readBy: (json['read_by'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      imageUrl: json['image_url'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }
}
