import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/chat_provider.dart';
import 'package:my_chat_app/screens/chat_page.dart';

import 'package:my_chat_app/utils/error_utils.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    if (_formKey.currentState!.validate()) {
      final chatProvider = context.read<ChatProvider>();
      final navigator = Navigator.of(context);

      try {
        await chatProvider.saveNickname(_nicknameController.text.trim());
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
      } catch (e, s) {
        if (mounted) showErrorSnackBar(context, e, s);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('닉네임 설정')),
      body: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  hintText: '사용하실 닉네임을 입력하세요',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '닉네임을 입력해주세요.';
                  }
                  if (value.trim().length < 2 || value.trim().length > 10) {
                    return '닉네임은 2자 이상 10자 이하로 입력해주세요.';
                  }
                  if (RegExp(r'[\s!@#\$%^&*(),.?":{}|<>]+').hasMatch(value)) {
                    return '닉네임에 공백이나 특수문자를 사용할 수 없습니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: UIConstants.spacingMedium * 2.5), // 20.0
              ElevatedButton(
                onPressed: _saveNickname,
                child: const Text('채팅 시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
