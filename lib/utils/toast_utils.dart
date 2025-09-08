import 'package:flutter/material.dart';
import '../widgets/custom_toast.dart';

/// 커스텀 토스트 메시지를 화면에 표시하는 유틸리티 클래스입니다.
class ToastUtils {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// 화면에 커스텀 토스트 메시지를 표시합니다.
  ///
  /// 이미 토스트가 표시되고 있는 경우, 기존 토스트를 제거하고 새로운 토스트를 표시합니다.
  ///
  /// [context] `Overlay`에 접근하기 위한 `BuildContext`입니다.
  /// [message] 토스트에 표시할 메시지입니다.
  /// [duration] 토스트가 화면에 표시될 시간입니다. 기본값은 2초입니다.
  static void showToast(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (_isShowing) {
      _overlayEntry?.remove();
      _isShowing = false;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => CustomToast(
        message: message,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isShowing = true;

    Future.delayed(duration, () {
      if (_overlayEntry != null) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _isShowing = false;
      }
    });
  }
}
