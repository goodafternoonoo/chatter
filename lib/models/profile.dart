class Profile {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final String? statusMessage;
  final DateTime? lastSeen; // last_seen 필드 추가
  final bool isOnline; // is_online 필드 추가

  Profile({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    this.statusMessage,
    this.lastSeen,
    this.isOnline = false, // 기본값 false
  });

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
