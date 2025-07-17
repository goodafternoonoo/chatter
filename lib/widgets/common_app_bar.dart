import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/models/theme_mode_provider.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const CommonAppBar({
    super.key,
    this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeModeProvider = context.watch<ThemeModeProvider>();
    final isDarkMode = themeModeProvider.themeMode == ThemeMode.dark;

    return AppBar(
      title: title,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: [
        IconButton(
          icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: themeModeProvider.toggleTheme,
        ),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
