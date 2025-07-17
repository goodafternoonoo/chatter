import 'package:flutter/material.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

class ProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nicknameController;
  final TextEditingController statusMessageController;
  final VoidCallback onSave;
  final String buttonText;

  const ProfileForm({
    super.key,
    required this.formKey,
    required this.nicknameController,
    required this.statusMessageController,
    required this.onSave,
    this.buttonText = '프로필 저장',
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '닉네임을 입력해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: UIConstants.spacingMedium),
            TextFormField(
              controller: statusMessageController,
              decoration: const InputDecoration(
                labelText: '상태 메시지',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: UIConstants.spacingMedium * 2),
            ElevatedButton(
              onPressed: onSave,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
