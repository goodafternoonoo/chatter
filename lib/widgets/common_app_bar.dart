import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/models/theme_mode_provider.dart';
import 'package:window_manager/window_manager.dart';

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

    return PreferredSize(
      preferredSize: preferredSize,
      child: DragToMoveArea(
        child: AppBar(
          title: title,
          automaticallyImplyLeading: automaticallyImplyLeading,
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: themeModeProvider.toggleTheme,
            ),
            ...?actions,
            const WindowButtons(), // 창 제어 버튼 추가
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.minimize),
          onPressed: () async {
            await windowManager.minimize();
          },
        ),
        IconButton(
          icon: const Icon(Icons.crop_square),
          onPressed: () async {
            bool isMaximized = await windowManager.isMaximized();
            if (isMaximized) {
              await windowManager.restore();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            await windowManager.close();
          },
        ),
      ],
    );
  }
}
