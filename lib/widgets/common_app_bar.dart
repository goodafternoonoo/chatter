import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/models/theme_mode_provider.dart';
import 'package:window_manager/window_manager.dart';

/// 앱 전체에서 사용되는 공통 앱바 위젯입니다.
///
/// 데스크톱 환경을 고려하여 창 드래그 이동, 테마 전환, 창 제어 버튼을 포함합니다.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 앱바에 표시될 제목 위젯입니다.
  final Widget? title;

  /// 앱바에 추가될 액션 버튼 목록입니다.
  final List<Widget>? actions;

  /// 뒤로가기 버튼의 자동 표시 여부입니다.
  final bool automaticallyImplyLeading;

  /// {@template common_app_bar}
  /// `CommonAppBar` 위젯을 생성합니다.
  /// {@endtemplate}
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
      child: AppBar(
        centerTitle: false, // title이 가능한 한 많은 공간을 차지하도록 설정
        // DragToMoveArea를 사용하여 앱바의 빈 공간을 드래그하여 창을 이동할 수 있도록 합니다.
        title: DragToMoveArea(
          child: Align(
            alignment: Alignment.centerLeft, // title의 기본 정렬 유지
            child: title ?? const SizedBox.shrink(),
          ),
        ),
        automaticallyImplyLeading: automaticallyImplyLeading,
        actions: [
          // 테마 전환 버튼
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: themeModeProvider.toggleTheme,
          ),
          // 추가적인 액션 버튼들
          ...?actions,
          // Windows/macOS/Linux용 창 제어 버튼
          const WindowButtons(),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// 데스크톱 앱의 창 제어(최소화, 최대화/복원, 닫기) 버튼을 제공하는 위젯입니다.
class WindowButtons extends StatelessWidget {
  /// {@template window_buttons}
  /// `WindowButtons` 위젯을 생성합니다.
  /// {@endtemplate}
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
