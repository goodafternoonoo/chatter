import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_chat_app/themes/app_themes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'models/theme_mode_provider.dart';
import 'package:my_chat_app/utils/notification_service.dart';
import 'package:my_chat_app/providers/chat_provider.dart'; // ChatProvider 임포트
import 'package:my_chat_app/routes/app_router.dart'; // app_router 임포트

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await initializeDateFormatting('ko', null);
  await NotificationService.initializeNotifications();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeModeProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider(roomId: '')..initialize()),
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

    return MaterialApp.router(
      title: 'Supabase Chat App',
      themeMode: themeMode,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      routerConfig: appRouter, // go_router 인스턴스 적용
      debugShowCheckedModeBanner: true,
    );
  }
}