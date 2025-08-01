import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeModeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
    _saveThemeMode(_themeMode);
  }

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

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = mode.toString().split('.').last;
    await prefs.setString('theme_mode', modeString);
  }
}
