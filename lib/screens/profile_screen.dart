import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/profile_provider.dart';
import 'package:my_chat_app/utils/error_utils.dart';
import 'package:my_chat_app/constants/ui_constants.dart';
import 'package:my_chat_app/constants/app_constants.dart';

import 'package:my_chat_app/widgets/profile/profile_avatar.dart';
import 'package:my_chat_app/widgets/profile/profile_form.dart';
import 'package:my_chat_app/widgets/common_app_bar.dart';

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
  late bool _isInitialSetup;

  @override
  void initState() {
    super.initState();
    _profileProvider = context.read<ProfileProvider>();
    _profileProvider.addListener(_updateControllers);
    _updateControllers();
    _isInitialSetup = _profileProvider.currentNickname == AppConstants.defaultNickname;
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
      try {
        await _profileProvider.uploadAvatar(image);
      } catch (e, s) {
        if (mounted) showErrorSnackBar(context, e, s);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _profileProvider.updateProfile(
          nickname: _nicknameController.text.trim(),
          statusMessage: _statusMessageController.text.trim(),
        );
        if (!mounted) return;
        if (_isInitialSetup) {
          context.go('/rooms');
        } else {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/rooms'); // Fallback to rooms if nothing to pop
          }
        }
      } catch (e, s) {
        if (mounted) showErrorSnackBar(context, e, s);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: null, // 기본 AppBar 제거
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileProvider.error != null
              ? Center(child: Text('오류: ${profileProvider.error}'))
              : Column(
                  children: [
                    CommonAppBar(
                      title: Text(_isInitialSetup ? '닉네임 설정' : '프로필 관리'),
                      automaticallyImplyLeading: !_isInitialSetup,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(UIConstants.paddingMedium),
                        child: Column(
                          children: [
                            ProfileAvatar(
                              avatarUrl: profileProvider.currentProfile?.avatarUrl,
                              onTap: _pickImage,
                            ),
                            const SizedBox(height: UIConstants.spacingMedium),
                            ProfileForm(
                              formKey: _formKey,
                              nicknameController: _nicknameController,
                              statusMessageController: _statusMessageController,
                              onSave: _saveProfile,
                              buttonText: _isInitialSetup ? '채팅 시작하기' : '프로필 저장',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}