import 'package:flutter/material.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

class AppThemes {
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.blueGrey,
    brightness: Brightness.light,
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.blueGrey,
    brightness: Brightness.dark,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'NotoSansKR',
      colorScheme: _lightColorScheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: _lightColorScheme.primary,
        foregroundColor: _lightColorScheme.onPrimary,
        titleTextStyle: TextStyle(
          color: _lightColorScheme.onPrimary,
          fontSize: UIConstants.appBarTitleFontSize,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: UIConstants.fontSizeLarge,
          color: _lightColorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: UIConstants.fontSizeMedium,
          color: _lightColorScheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: UIConstants.fontSizeSmall,
          color: _lightColorScheme.onSurface,
        ),
        labelLarge: TextStyle(
          fontSize: UIConstants.fontSizeMedium,
          fontWeight: FontWeight.bold,
          color: _lightColorScheme.onPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: UIConstants.fontSizeSmall,
          color: _lightColorScheme.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: UIConstants.fontSizeXSmall,
          color: _lightColorScheme.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightColorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusCircular),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UIConstants.messageInputHorizontalPadding,
          vertical: UIConstants.messageInputVerticalPadding,
        ),
        hintStyle: TextStyle(color: _lightColorScheme.onSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _lightColorScheme.primaryContainer,
        foregroundColor: _lightColorScheme.onPrimaryContainer,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightColorScheme.primary,
          foregroundColor: _lightColorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              UIConstants.borderRadiusCircular,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.paddingMedium,
            vertical: UIConstants.paddingSmall,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: _lightColorScheme.surface,
        elevation: UIConstants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusCircular),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      fontFamily: 'NotoSansKR',
      colorScheme: _darkColorScheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: _darkColorScheme.primary,
        foregroundColor: _darkColorScheme.onPrimary,
        titleTextStyle: TextStyle(
          color: _darkColorScheme.onPrimary,
          fontSize: UIConstants.appBarTitleFontSize,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: UIConstants.fontSizeLarge,
          color: _darkColorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: UIConstants.fontSizeMedium,
          color: _darkColorScheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: UIConstants.fontSizeSmall,
          color: _darkColorScheme.onSurface,
        ),
        labelLarge: TextStyle(
          fontSize: UIConstants.fontSizeMedium,
          fontWeight: FontWeight.bold,
          color: _darkColorScheme.onPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: UIConstants.fontSizeSmall,
          color: _darkColorScheme.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: UIConstants.fontSizeXSmall,
          color: _darkColorScheme.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkColorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusCircular),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UIConstants.messageInputHorizontalPadding,
          vertical: UIConstants.messageInputVerticalPadding,
        ),
        hintStyle: TextStyle(color: _darkColorScheme.onSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkColorScheme.primaryContainer,
        foregroundColor: _darkColorScheme.onPrimaryContainer,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkColorScheme.primary,
          foregroundColor: _darkColorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              UIConstants.borderRadiusCircular,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.paddingMedium,
            vertical: UIConstants.paddingSmall,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: _darkColorScheme.surface,
        elevation: UIConstants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusCircular),
        ),
      ),
    );
  }
}
