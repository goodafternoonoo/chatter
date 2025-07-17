import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/models/theme_mode_provider.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showSearchField;
  final VoidCallback onToggleSearch;
  final VoidCallback onToggleTheme;

  const ChatAppBar({
    super.key,
    required this.showSearchField,
    required this.onToggleSearch,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final themeModeProvider = context.watch<ThemeModeProvider>();

    return AppBar(
      title: const Text('실시간 채팅'),
      actions: [
        IconButton(
          icon: Icon(
            showSearchField ? Icons.close : Icons.search,
          ),
          onPressed: onToggleSearch,
          tooltip: '메시지 검색',
        ),
        IconButton(
          icon: Icon(
            themeModeProvider.themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          onPressed: onToggleTheme,
          tooltip: '테마 전환',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
