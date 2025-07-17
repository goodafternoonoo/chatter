import 'package:flutter/material.dart';
import '../widgets/custom_toast.dart';

class ToastUtils {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  static void showToast(
    BuildContext context,
    String message,
    {
      Duration duration = const Duration(seconds: 2),
    }
  ) {
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
