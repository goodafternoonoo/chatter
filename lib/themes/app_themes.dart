
import 'package:flutter/material.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'NotoSansKR',
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: UIConstants.appBarTitleFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: UIConstants.fontSizeLarge),
        bodyMedium: TextStyle(fontSize: UIConstants.fontSizeMedium),
        bodySmall: TextStyle(fontSize: UIConstants.fontSizeSmall),
        labelLarge: TextStyle(fontSize: UIConstants.fontSizeMedium, fontWeight: FontWeight.bold),
        labelMedium: TextStyle(fontSize: UIConstants.fontSizeSmall),
        labelSmall: TextStyle(fontSize: UIConstants.fontSizeXSmall),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusCircular),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: UIConstants.messageInputHorizontalPadding, vertical: UIConstants.messageInputVerticalPadding),
        hintStyle: TextStyle(color: Colors.grey[600]),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.blueGrey[700],
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      fontFamily: 'NotoSansKR',
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueGrey,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: UIConstants.appBarTitleFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: UIConstants.fontSizeLarge),
        bodyMedium: TextStyle(fontSize: UIConstants.fontSizeMedium),
        bodySmall: TextStyle(fontSize: UIConstants.fontSizeSmall),
        labelLarge: TextStyle(fontSize: UIConstants.fontSizeMedium, fontWeight: FontWeight.bold),
        labelMedium: TextStyle(fontSize: UIConstants.fontSizeSmall),
        labelSmall: TextStyle(fontSize: UIConstants.fontSizeXSmall),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusCircular),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: UIConstants.messageInputHorizontalPadding, vertical: UIConstants.messageInputVerticalPadding),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.blueGrey[700],
        foregroundColor: Colors.white,
      ),
    );
  }
}
