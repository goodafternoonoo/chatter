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

/// 사용자 프로필을 설정하거나 수정하는 화면입니다.
///
/// 이 화면은 두 가지 시나리오에서 사용됩니다:
/// 1. 앱 최초 실행 시 닉네임 설정
/// 2. 설정 메뉴를 통한 기존 프로필 정보(아바타, 닉네임, 상태 메시지) 수정
class ProfileScreen extends StatefulWidget {
  /// {@template profile_screen}
  /// `ProfileScreen` 위젯을 생성합니다.
  /// {@endtemplate}
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nicknameController = TextEditingController();
  final _statusMessageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final ProfileProvider _profileProvider;

  /// 현재 화면이 '최초 닉네임 설정' 모드인지 여부를 결정합니다.
  late final bool _isInitialSetup;

  @override
  void initState() {
    super.initState();
    _profileProvider = context.read<ProfileProvider>();
    // ProfileProvider의 상태가 변경될 때마다 텍스트 컨트롤러를 업데이트합니다.
    _profileProvider.addListener(_updateControllers);
    _updateControllers();
    // 현재 닉네임이 기본값과 같으면 최초 설정으로 간주합니다.
    _isInitialSetup =
        _profileProvider.currentNickname == AppConstants.defaultNickname;
  }

  @override
  void dispose() {
    _profileProvider.removeListener(_updateControllers);
    _nicknameController.dispose();
    _statusMessageController.dispose();
    super.dispose();
  }

  /// `ProfileProvider`의 데이터로 텍스트 필드를 채웁니다.
  void _updateControllers() {
    final profile = _profileProvider.currentProfile;
    if (profile != null) {
      _nicknameController.text = profile.nickname;
      _statusMessageController.text = profile.statusMessage ?? '';
    }
  }

  /// 갤러리에서 이미지를 선택하여 아바타로 업로드합니다.
  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      if (mounted) await context.read<ProfileProvider>().uploadAvatar(image);
    } catch (e, s) {
      if (mounted) showErrorSnackBar(context, e, s);
    }
  }

  /// 폼의 유효성을 검사하고, 유효하면 프로필 정보를 저장(업데이트)합니다.
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _profileProvider.updateProfile(
          nickname: _nicknameController.text.trim(),
          statusMessage: _statusMessageController.text.trim(),
        );
        if (!mounted) return;

        // 최초 설정 모드에서는 메인 화면으로 이동합니다.
        if (_isInitialSetup) {
          context.go('/main');
        } else {
          // 프로필 수정 모드에서는 이전 화면으로 돌아갑니다.
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/main'); // 돌아갈 화면이 없는 경우 메인으로 이동
          }
        }
      } catch (e, s) {
        if (mounted) showErrorSnackBar(context, e, s);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 및 에러 상태에 따라 다른 UI를 표시합니다.
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return Scaffold(
          appBar: null,
          body: profileProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : profileProvider.error != null
                  ? Center(child: Text('오류: ${profileProvider.error}'))
                  : Column(
                      children: [
                        CommonAppBar(
                          title:
                              Text(_isInitialSetup ? '닉네임 설정' : '프로필 관리'),
                          automaticallyImplyLeading: !_isInitialSetup,
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(UIConstants.paddingMedium),
                            child: Column(
                              children: [
                                ProfileAvatar(
                                  avatarUrl:
                                      profileProvider.currentProfile?.avatarUrl,
                                  onTap: _pickImage,
                                ),
                                const SizedBox(
                                    height: UIConstants.spacingMedium),
                                ProfileForm(
                                  formKey: _formKey,
                                  nicknameController: _nicknameController,
                                  statusMessageController:
                                      _statusMessageController,
                                  onSave: _saveProfile,
                                  buttonText:
                                      _isInitialSetup ? '채팅 시작하기' : '프로필 저장',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}
