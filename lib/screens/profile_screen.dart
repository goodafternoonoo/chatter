import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/profile_provider.dart'; // ProfileProvider 임포트 예정
import 'package:my_chat_app/utils/error_utils.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nicknameController = TextEditingController();
  final _statusMessageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late ProfileProvider _profileProvider;

  @override
  void initState() {
    super.initState();
    _profileProvider = context.read<ProfileProvider>();
    _profileProvider.addListener(_updateControllers);
    _updateControllers(); // 초기 로드 시 값 설정
  }

  @override
  void dispose() {
    _profileProvider.removeListener(_updateControllers);
    _nicknameController.dispose();
    _statusMessageController.dispose();
    super.dispose();
  }

  void _updateControllers() {
    _nicknameController.text = _profileProvider.currentProfile?.nickname ?? '';
    _statusMessageController.text = _profileProvider.currentProfile?.statusMessage ?? '';
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (!mounted) return;
      final profileProvider = context.read<ProfileProvider>();
      try {
        await profileProvider.uploadAvatar(image);
      } catch (e, s) {
        if (mounted) showErrorSnackBar(context, e, s);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final profileProvider = context.read<ProfileProvider>();
      try {
        await profileProvider.updateProfile(
          nickname: _nicknameController.text.trim(),
          statusMessage: _statusMessageController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 성공적으로 업데이트되었습니다.')),
        );
        context.pop(); // 저장 후 이전 화면으로 돌아가기
      } catch (e, s) {
        if (mounted) showErrorSnackBar(context, e, s);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 관리'),
      ),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileProvider.error != null
              ? Center(child: Text('오류: ${profileProvider.error}'))
              : Padding(
                  padding: const EdgeInsets.all(UIConstants.paddingMedium),
                  child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: profileProvider.currentProfile?.avatarUrl != null
                              ? NetworkImage(profileProvider.currentProfile!.avatarUrl!)
                              : null,
                          child: profileProvider.currentProfile?.avatarUrl == null
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                      ),
                      const SizedBox(height: UIConstants.spacingMedium),
                      TextFormField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          labelText: '닉네임',
                          border: OutlineInputBorder(),
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
                        controller: _statusMessageController,
                        decoration: const InputDecoration(
                          labelText: '상태 메시지',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: UIConstants.spacingMedium * 2),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('프로필 저장'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
