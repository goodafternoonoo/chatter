import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/profile_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:my_chat_app/constants/app_constants.dart';

/// 앱 시작 시 표시되는 스플래시 화면입니다.
///
/// 필요한 초기화 작업을 수행하고, 사용자의 닉네임 설정 여부에 따라
/// 적절한 화면으로 사용자를 안내하는 역할을 합니다.
class SplashScreen extends StatefulWidget {
  /// {@template splash_screen}
  /// `SplashScreen` 위젯을 생성합니다.
  /// {@endtemplate}
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 위젯이 렌더링된 후 초기화 및 화면 이동 로직을 실행합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndNavigate();
    });
  }

  /// `ProfileProvider`를 초기화하고 결과에 따라 다음 화면으로 이동합니다.
  Future<void> _initializeAndNavigate() async {
    final profileProvider = context.read<ProfileProvider>();
    // 프로필 초기화 (로컬 ID 로드, DB에서 프로필 정보 가져오기 등)
    await profileProvider.initialize();

    // 위젯이 여전히 마운트 상태인지 확인합니다.
    if (!mounted) return;

    // 닉네임이 설정되지 않았다면 프로필 설정 화면으로 이동합니다.
    if (profileProvider.currentNickname == AppConstants.defaultNickname) {
      context.go('/profile');
    } else {
      // 닉네임이 설정되어 있다면 메인 화면으로 이동합니다.
      context.go('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 초기화가 진행되는 동안 로딩 인디케이터를 표시합니다.
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
