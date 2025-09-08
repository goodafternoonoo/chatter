import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱의 테마 모드(라이트/다크/시스템)를 관리하는 클래스입니다.
///
/// `ChangeNotifier`를 사용하여 테마 변경을 감지하고 UI에 알립니다.
/// 사용자의 테마 설정은 `SharedPreferences`를 통해 로컬에 저장됩니다.
class ThemeModeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  /// {@template theme_mode_provider}
  /// `ThemeModeProvider`의 인스턴스를 생성하고,
  /// 저장된 테마 설정을 불러옵니다.
  /// {@endtemplate}
  ThemeModeProvider() {
    _loadThemeMode();
  }

  /// 현재 적용된 테마 모드를 반환합니다.
  ThemeMode get themeMode => _themeMode;

  /// 라이트 모드와 다크 모드를 전환합니다.
  ///
  /// 현재 테마가 라이트 모드이면 다크 모드로, 다크 모드이면 라이트 모드로 변경합니다.
  /// 변경된 테마는 로컬에 저장되고, UI에 즉시 반영됩니다.
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    _saveThemeMode(_themeMode);
  }

  /// `SharedPreferences`에서 저장된 테마 설정을 불러옵니다.
  ///
  /// 앱 시작 시 호출되어 이전에 설정한 테마를 복원합니다.
  /// 저장된 값이 없으면 시스템 기본 설정을 따릅니다.
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('theme_mode');
    if (themeModeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// 현재 테마 모드를 `SharedPreferences`에 저장합니다.
  ///
  /// [mode] 저장할 테마 모드입니다.
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = mode.toString().split('.').last;
    await prefs.setString('theme_mode', modeString);
  }
}
