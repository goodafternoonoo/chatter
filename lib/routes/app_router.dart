import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:my_chat_app/providers/chat_provider.dart';
import 'package:my_chat_app/providers/profile_provider.dart';
import 'package:my_chat_app/screens/splash_screen.dart';

import 'package:my_chat_app/screens/room_list_screen.dart';
import 'package:my_chat_app/screens/chat_page.dart';
import 'package:my_chat_app/screens/profile_screen.dart';
import 'package:my_chat_app/screens/main_page.dart';
import 'package:provider/provider.dart';

/// 앱의 전체적인 내비게이션을 관리하는 `GoRouter` 인스턴스입니다.
///
/// 각 화면(경로)에 대한 라우트를 정의하고, 필요한 경우 Provider를 주입합니다.
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    /// 앱의 시작점인 스플래시 화면입니다.
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),

    /// 닉네임 설정 후 진입하는 메인 페이지입니다.
    GoRoute(
      path: '/main',
      builder: (BuildContext context, GoRouterState state) {
        return const MainPage();
      },
    ),

    /// 채팅방 목록을 보여주는 화면입니다.
    GoRoute(
      path: '/rooms',
      builder: (BuildContext context, GoRouterState state) {
        return const RoomListScreen();
      },
    ),

    /// 특정 채팅방의 채팅 화면입니다.
    ///
    /// 경로 파라미터로 `roomId`를 받아서 해당 채팅방의 `ChatProvider`를 생성하고,
    /// `ChatPage`에 주입합니다.
    GoRoute(
      path: '/chat/:roomId',
      builder: (BuildContext context, GoRouterState state) {
        final roomId = state.pathParameters['roomId']!;
        return ChangeNotifierProvider(
          create: (context) => ChatProvider(
            roomId: roomId,
            profileProvider: context.read<ProfileProvider>(),
          )..initialize(),
          child: ChatPage(roomId: roomId),
        );
      },
    ),

    /// 사용자 프로필을 설정하는 화면입니다.
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) {
        return const ProfileScreen();
      },
    ),
  ],
);
