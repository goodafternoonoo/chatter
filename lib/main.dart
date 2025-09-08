import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_chat_app/themes/app_themes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'models/theme_mode_provider.dart';
import 'package:my_chat_app/utils/notification_service.dart';
import 'package:my_chat_app/providers/profile_provider.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:my_chat_app/routes/app_router.dart';
import 'package:my_chat_app/repositories/room_repository.dart';
import 'package:my_chat_app/repositories/chat_repository.dart';
import 'package:my_chat_app/providers/room_provider.dart';
import 'package:window_manager/window_manager.dart';

/// 앱의 메인 진입점입니다.
///
/// 이 함수는 앱 실행에 필요한 모든 초기화 작업을 수행합니다.
/// - Flutter 바인딩 초기화
/// - 데스크톱 창 관리자 설정 (크기, 제목 표시줄 등)
/// - 전역 에러 핸들러 설정
/// - 환경 변수 로드 (`.env`)
/// - Supabase 클라이언트 초기화
/// - 날짜 형식 로케일 설정
/// - 로컬 알림 서비스 초기화
/// - `MultiProvider`를 사용한 앱 전역 상태(Provider) 설정
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 데스크톱 플랫폼(Windows, macOS, Linux)을 위한 창 관리자 초기화
  await windowManager.ensureInitialized();

  // 창 옵션 설정
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // 창 제목 표시줄을 숨겨 커스텀 AppBar 사용
  );
  // 창이 표시될 준비가 될 때까지 기다린 후 표시 및 포커스
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 전역 에러 핸들러 설정
  // 릴리즈 모드에서 사용자에게 친화적인 에러 메시지를 보여주기 위함
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // 디버그 모드에서는 기본 에러 위젯 표시
      return ErrorWidget(details.exception);
    }
    // 릴리즈 모드에서는 간단한 텍스트 메시지 표시
    return Container(
      alignment: Alignment.center,
      child: const Text(
        '오류가 발생했습니다.\n앱을 다시 시작해주세요.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  };

  // Flutter 프레임워크에서 발생하는 에러를 처리
  FlutterError.onError = (FlutterErrorDetails details) {
    // 디버그 모드에서는 콘솔에 에러 로그 출력
    if (kDebugMode) {
      FlutterError.presentError(details);
      log(
        'Flutter Error',
        name: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
      );
    }
    // TODO: 릴리즈 모드에서는 Sentry, Crashlytics 같은 원격 로깅 서비스에 에러 전송
  };

  // .env 파일에서 환경 변수 로드
  await dotenv.load();
  // Supabase 클라이언트 초기화
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  // 한국어 날짜 형식 초기화
  await initializeDateFormatting('ko', null);
  // 로컬 알림 서비스 초기화
  await NotificationService.initializeNotifications();

  // 앱 실행
  runApp(
    // 앱 전역에서 사용할 Provider들을 설정
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        // RoomProvider는 ProfileProvider에 의존하므로 순서가 중요
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

/// 앱의 루트 위젯입니다.
///
/// `MaterialApp.router`를 사용하여 `go_router` 기반의 내비게이션을 설정하고,
/// `ThemeModeProvider`를 통해 라이트/다크 테마를 적용합니다.
/// 또한 `WindowListener`를 구현하여 창 닫기 이벤트를 처리합니다.
class MyApp extends StatefulWidget {
  /// {@template my_app}
  /// `MyApp` 위젯을 생성합니다.
  /// {@endtemplate}
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

  /// 창 닫기 이벤트를 가로채도록 설정합니다.
  void _init() async {
    await windowManager.setPreventClose(true);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeModeProvider>().themeMode;

    return MaterialApp.router(
      title: 'Supabase Chat App',
      themeMode: themeMode,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }

  /// 사용자가 창의 닫기 버튼을 눌렀을 때 호출됩니다.
  @override
  void onWindowClose() async {
    // 앱이 정상적으로 종료될 수 있도록 창을 완전히 파괴합니다.
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      if (mounted) {
        // TODO: 필요한 경우 리소스 정리 또는 사용자 확인 로직 추가
        await windowManager.destroy();
      }
    }
  }
}
