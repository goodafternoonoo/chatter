/// 사용자 프로필을 나타내는 데이터 모델 클래스입니다.
///
/// 이 클래스는 Supabase의 `profiles` 테이블과 일대일로 매핑됩니다.
class Profile {
  /// 사용자의 고유 ID입니다. (UUID)
  final String id;

  /// 사용자의 닉네임입니다.
  final String nickname;

  /// 사용자의 아바타 이미지 URL입니다.
  ///
  /// Supabase Storage의 `avatars` 버킷에 저장된 이미지의 URL입니다.
  final String? avatarUrl;

  /// 사용자의 상태 메시지입니다.
  final String? statusMessage;

  /// 사용자의 마지막 접속 시간입니다.
  final DateTime? lastSeen;

  /// 사용자의 온라인 상태 여부입니다.
  final bool isOnline;

  /// {@template profile}
  /// `Profile` 클래스의 인스턴스를 생성합니다.
  /// {@endtemplate}
  Profile({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    this.statusMessage,
    this.lastSeen,
    this.isOnline = false,
  });

  /// JSON 맵에서 `Profile` 인스턴스를 생성하는 팩토리 생성자입니다.
  ///
  /// Supabase에서 받은 데이터를 파싱하는 데 사용됩니다.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatar_url'] as String?,
      statusMessage: json['status_message'] as String?,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String).toLocal()
          : null,
      isOnline: json['is_online'] as bool? ?? false,
    );
  }

  /// `Profile` 인스턴스를 JSON 맵으로 변환합니다.
  ///
  /// Supabase에 데이터를 전송할 때 사용됩니다.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'status_message': statusMessage,
      'last_seen': lastSeen?.toIso8601String(),
      'is_online': isOnline,
    };
  }

  /// `Profile` 객체의 복사본을 생성하되, 지정된 필드의 값을 변경합니다.
  ///
  /// 객체의 불변성을 유지하면서 특정 속성만 수정할 때 유용합니다.
  Profile copyWith({
    String? id,
    String? nickname,
    String? avatarUrl,
    String? statusMessage,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return Profile(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
