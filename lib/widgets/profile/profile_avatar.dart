import 'package:flutter/material.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

/// 사용자 프로필 아바타를 표시하는 위젯입니다.
///
/// 아바타 이미지가 있는 경우 네트워크 이미지를 표시하고, 없는 경우 기본 아이콘을 표시합니다.
/// 탭하면 `onTap` 콜백을 실행하여 이미지 변경 등의 동작을 트리거할 수 있습니다.
class ProfileAvatar extends StatelessWidget {
  /// 표시할 아바타 이미지의 URL입니다.
  ///
  /// `null`인 경우 기본 사용자 아이콘이 표시됩니다.
  final String? avatarUrl;

  /// 아바타를 탭했을 때 호출될 콜백 함수입니다.
  final VoidCallback onTap;

  /// {@template profile_avatar}
  /// `ProfileAvatar` 위젯을 생성합니다.
  /// {@endtemplate}
  const ProfileAvatar({super.key, this.avatarUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: UIConstants.avatarRadius * 2,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        backgroundColor: colorScheme.primaryContainer,
        child: avatarUrl == null
            ? Icon(Icons.person,
                size: UIConstants.avatarRadius * 2,
                color: colorScheme.onPrimaryContainer)
            : null,
      ),
    );
  }
}
