import 'package:flutter/material.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

/// 사용자 프로필(닉네임, 상태 메시지)을 입력받는 폼 위젯입니다.
///
/// 닉네임에 대한 유효성 검사를 포함하며, 저장 버튼 클릭 시 `onSave` 콜백을 호출합니다.
class ProfileForm extends StatelessWidget {
  /// 폼의 상태를 관리하기 위한 글로벌 키입니다.
  final GlobalKey<FormState> formKey;

  /// 닉네임 입력 필드를 제어하는 컨트롤러입니다.
  final TextEditingController nicknameController;

  /// 상태 메시지 입력 필드를 제어하는 컨트롤러입니다.
  final TextEditingController statusMessageController;

  /// 저장 버튼을 눌렀을 때 호출될 콜백 함수입니다.
  final VoidCallback onSave;

  /// 저장 버튼에 표시될 텍스트입니다.
  final String buttonText;

  /// {@template profile_form}
  /// `ProfileForm` 위젯을 생성합니다.
  /// {@endtemplate}
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
