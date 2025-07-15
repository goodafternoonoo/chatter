class Profile {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final String? statusMessage;

  Profile({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    this.statusMessage,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatar_url'] as String?,
      statusMessage: json['status_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'status_message': statusMessage,
    };
  }

  Profile copyWith({
    String? id,
    String? nickname,
    String? avatarUrl,
    String? statusMessage,
  }) {
    return Profile(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
