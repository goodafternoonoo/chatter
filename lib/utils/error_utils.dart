import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void showErrorSnackBar(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
) {
  if (kDebugMode) {
    print('오류 발생: $error');
    if (stackTrace != null) {
      print(stackTrace);
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.toString()),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

void showErrorMessage(BuildContext context, String message) {
  if (kDebugMode) {
    print('오류 발생: $message');
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}
