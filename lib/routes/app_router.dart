import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:my_chat_app/providers/chat_provider.dart';
import 'package:my_chat_app/providers/profile_provider.dart'; // ProfileProvider 임포트
import 'package:my_chat_app/screens/splash_screen.dart';

import 'package:my_chat_app/screens/room_list_screen.dart';
import 'package:my_chat_app/screens/chat_page.dart';
import 'package:my_chat_app/screens/profile_screen.dart'; // ProfileScreen 임포트
import 'package:my_chat_app/screens/main_page.dart'; // MainPage 임포트 추가
import 'package:provider/provider.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/main',
      builder: (BuildContext context, GoRouterState state) {
        return const MainPage();
      },
    ),

    GoRoute(
      path: '/rooms',
      builder: (BuildContext context, GoRouterState state) {
        return const RoomListScreen();
      },
    ),
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
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) {
        return const ProfileScreen();
      },
    ),
  ],
);
