import 'package:flutter/material.dart';

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
        radius: 60,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        backgroundColor: colorScheme.primaryContainer,
        child: avatarUrl == null
            ? Icon(Icons.person, size: 60, color: colorScheme.onPrimaryContainer)
            : null,
      ),
    );
  }
}
