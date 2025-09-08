import 'package:flutter/material.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

/// 화면 상단에 잠시 나타났다 사라지는 커스텀 토스트 메시지 위젯입니다.
///
/// `ToastUtils`를 통해 사용되는 것을 의도하고 만들어졌습니다.
class CustomToast extends StatelessWidget {
  /// 토스트에 표시될 메시지 내용입니다.
  final String message;

  /// {@template custom_toast}
  /// `CustomToast` 위젯을 생성합니다.
  /// {@endtemplate}
  const CustomToast({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 50.0),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusCircular),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withAlpha(25),
                blurRadius: UIConstants.cardElevation * 2,
                offset: const Offset(0, UIConstants.cardElevation),
              ),
            ],
          ),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
        ),
      ),
    );
  }
}
