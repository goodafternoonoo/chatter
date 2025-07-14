import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_chat_app/themes/app_themes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'models/theme_mode_provider.dart';

import 'package:my_chat_app/screens/splash_screen.dart';

import 'package:my_chat_app/providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await initializeDateFormatting('ko', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeModeProvider()),
        // ChatProvider는 이제 ChatPage에서 개별적으로 생성됩니다.
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeModeProvider>().themeMode;

    return MaterialApp(
      title: 'Supabase Chat App',
      themeMode: themeMode,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      home: ChangeNotifierProvider(
        create: (_) => ChatProvider(roomId: '')..initialize(), // 임시 Provider
        builder: (context, child) {
          return const SplashScreen();
        },
      ),
      debugShowCheckedModeBanner: true,
    );
  }
}
