import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/chat_provider.dart';
import 'package:my_chat_app/providers/profile_provider.dart'; // ProfileProvider 임포트
import 'package:my_chat_app/constants/app_constants.dart'; // AppConstants 임포트
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkNicknameAndNavigate();
  }

  Future<void> _checkNicknameAndNavigate() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = context.read<ChatProvider>();
      final profileProvider = context.read<ProfileProvider>(); // ProfileProvider 가져오기
      try {
        // ChatProvider가 초기화될 때까지 기다립니다.
        // 이 부분은 ChatProvider의 initialize()가 main.dart에서 호출되도록 변경되었으므로
        // 여기서는 단순히 초기화 상태를 확인합니다.
        if (!chatProvider.isInitialized) {
          // 초기화가 완료될 때까지 잠시 기다립니다.
          // 실제 앱에서는 로딩 스피너 등을 보여줄 수 있습니다.
          await Future.delayed(const Duration(milliseconds: 500));
        }

        if (!mounted) return;

        if (chatProvider.error != null) {
          throw Exception(chatProvider.error);
        }

        if (profileProvider.currentNickname == AppConstants.defaultNickname) {
          context.go('/nickname');
        } else {
          context.go('/rooms');
        }
      } catch (e) {
        if (kDebugMode) {
        }
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = e.toString();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _hasError
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}