
import 'package:flutter/foundation.dart';
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
      try {
        if (!chatProvider.isInitialized) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        if (!mounted) return;

        if (chatProvider.error != null) {
          throw Exception(chatProvider.error);
        }

        if (chatProvider.currentNickname != '익명') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ChatPage()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const NicknameScreen()),
          );
        }
      } catch (e, s) {
        if (kDebugMode) {
          print('초기화 오류: $e');
          print(s);
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
