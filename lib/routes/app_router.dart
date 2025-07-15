import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:my_chat_app/providers/chat_provider.dart';
import 'package:my_chat_app/screens/splash_screen.dart';
import 'package:my_chat_app/screens/nickname_screen.dart';
import 'package:my_chat_app/screens/room_list_screen.dart';
import 'package:my_chat_app/screens/chat_page.dart';
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
      path: '/nickname',
      builder: (BuildContext context, GoRouterState state) {
        return const NicknameScreen();
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
          create: (_) => ChatProvider(roomId: roomId)..initialize(),
          child: ChatPage(roomId: roomId),
        );
      },
    ),
  ],
);
