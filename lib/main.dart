import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_chat_app/themes/app_themes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'models/theme_mode_provider.dart';
import 'package:my_chat_app/utils/notification_service.dart';
import 'package:my_chat_app/providers/chat_provider.dart'; // ChatProvider 임포트
import 'package:my_chat_app/providers/profile_provider.dart'; // ProfileProvider 임포트
import 'dart:developer'; // dart:developer 임포트
import 'package:flutter/foundation.dart'; // kDebugMode 사용을 위한 임포트
import 'package:my_chat_app/routes/app_router.dart'; // app_router 임포트
import 'package:my_chat_app/repositories/room_repository.dart';
import 'package:my_chat_app/repositories/chat_repository.dart'; // ChatRepository 임포트 추가
import 'package:my_chat_app/providers/room_provider.dart';
import 'package:window_manager/window_manager.dart'; // window_manager 임포트

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // window_manager 초기화
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // 제목 표시줄 숨기기
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 전역 에러 핸들러 설정
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // 디버그 모드에서는 기본 에러 위젯을 사용
      return ErrorWidget(details);
    }
    // 릴리즈 모드에서는 사용자 친화적인 메시지 표시
    return Container(
      alignment: Alignment.center,
      child: Text(
        '오류가 발생했습니다.\n앱을 다시 시작해주세요.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.red.shade900,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details); // Flutter 기본 에러 처리
    if (kDebugMode) {
      log(
        'Flutter Error',
        name: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
      );
    } else {
      // 릴리즈 모드에서는 에러를 로깅 서비스로 전송 (예: Firebase Crashlytics)
      // FirebaseCrashlytics.instance.recordFlutterError(details);
      log(
        'Flutter Error (Release Mode)',
        name: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
      );
    }
  };

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
        ChangeNotifierProvider(
          create: (context) => ProfileProvider()..initialize(),
        ), // ProfileProvider 먼저 초기화
        ChangeNotifierProvider(
          create: (context) => ChatProvider(
            roomId: '',
            profileProvider: context.read<ProfileProvider>(),
          )..initialize(),
        ), // ChatProvider에 ProfileProvider 전달
        ChangeNotifierProvider(
          create: (context) => RoomProvider(
            roomRepository: RoomRepository(),
            profileProvider: context.read<ProfileProvider>(),
            chatRepository: ChatRepository(Supabase.instance.client),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _init() async {
    await windowManager.setPreventClose(true);
    setState(() {});
  }

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

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      if (!mounted) return; // 위젯이 마운트되지 않았다면 리턴
      await windowManager.destroy();
    }
  }
}
