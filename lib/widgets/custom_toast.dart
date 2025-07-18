import 'package:flutter/material.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

class CustomToast extends StatelessWidget {
  final String message;

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
