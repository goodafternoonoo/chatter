import 'package:flutter/material.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback onTap;

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
            ? Icon(Icons.person, size: UIConstants.avatarRadius * 2, color: colorScheme.onPrimaryContainer)
            : null,
      ),
    );
  }
}
