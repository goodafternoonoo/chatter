import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 에러 발생 시 사용자에게 스낵바를 표시하는 유틸리티 함수입니다.
///
/// 디버그 모드에서는 콘솔에 상세한 로그를 함께 출력합니다.
///
/// [context] `ScaffoldMessenger`에 접근하기 위한 `BuildContext`입니다.
/// [error] 표시할 에러 객체입니다.
/// [stackTrace] 에러 발생 시의 스택 트레이스입니다.
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

/// 특정 오류 메시지를 사용자에게 스낵바로 표시하는 유틸리티 함수입니다.
///
/// [context] `ScaffoldMessenger`에 접근하기 위한 `BuildContext`입니다.
/// [message] 표시할 오류 메시지 문자열입니다.
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
