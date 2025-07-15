import 'dart:developer'; // dart:developer 임포트
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void showErrorSnackBar(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
) {
  if (kDebugMode) {
    log(
      '오류 발생',
      name: 'ErrorUtils',
      error: error,
      stackTrace: stackTrace,
    );
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
    log(
      '오류 발생: $message',
      name: 'ErrorUtils',
    );
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}
