
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/chat_provider.dart';
import 'package:my_chat_app/screens/chat_page.dart';
import 'package:my_chat_app/screens/nickname_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNicknameAndNavigate();
  }

  Future<void> _checkNicknameAndNavigate() async {
    // 위젯 트리가 빌드된 후에 Provider에 접근
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = context.read<ChatProvider>();
      
      // ChatProvider가 초기화될 때까지 기다림
      if (!chatProvider.isInitialized) {
        // isInitialized가 false이면 초기화가 완료될 때까지 기다려야 함
        // ChatProvider의 notifyListeners()를 기다리기 위해 listen: true로 변경
        // 하지만 initState에서는 listen: true를 사용할 수 없으므로, 다른 접근 방식이 필요.
        // 여기서는 간단히 Future.delayed를 사용하여 초기화 시간을 기다립니다.
        // 더 나은 방법은 FutureProvider를 사용하는 것입니다.
        await Future.delayed(const Duration(milliseconds: 500)); // 임시 방편
      }

      if (!mounted) return;

      if (chatProvider.currentNickname != '익명') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NicknameScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
