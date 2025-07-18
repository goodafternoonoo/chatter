import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/profile_provider.dart';

import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final ProfileProvider _profileProvider;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _profileProvider = context.read<ProfileProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_profileProvider.isLoading) {
        _onProfileChange();
      } else {
        _profileProvider.addListener(_onProfileChange);
      }
    });
  }

  void _onProfileChange() {
    if (_profileProvider.isLoading) return;

    _profileProvider.removeListener(_onProfileChange);

    if (!mounted) return;

    final error = _profileProvider.error;
    if (error != null) {
      setState(() {
        _hasError = true;
        _errorMessage = error;
      });
      return;
    }

    final profile = _profileProvider.currentProfile;
    // context.go('/main')으로 항상 이동
    context.go('/main');
  }

  @override
  void dispose() {
    _profileProvider.removeListener(_onProfileChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _hasError
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '오류가 발생했습니다: $_errorMessage',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              )
            : CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
      ),
    );
  }
}
