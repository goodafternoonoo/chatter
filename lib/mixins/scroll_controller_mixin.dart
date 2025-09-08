import 'package:flutter/material.dart';

/// `ListView`와 같은 스크롤 가능한 위젯에 "맨 아래로 스크롤" 기능을 쉽게 추가하기 위한 믹스인입니다.
///
/// 이 믹스인은 `StatefulWidget`의 `State` 클래스와 함께 사용되어야 합니다.
/// `ListView`가 `reverse: true`로 설정된 경우(예: 채팅 목록)를 가정하고 동작합니다.
mixin ScrollControllerMixin<T extends StatefulWidget> on State<T> {
  /// 스크롤 위치를 제어하는 컨트롤러입니다.
  final ScrollController scrollController = ScrollController();

  /// "맨 아래로 스크롤" 버튼의 표시 여부를 결정하는 상태 변수입니다.
  bool showScrollToBottomButton = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  /// 스크롤 이벤트를 감지하여 버튼 표시 여부를 결정합니다.
  ///
  /// 사용자가 스크롤을 위로 올려 최신 메시지(스크롤 맨 아래)에서 멀어지면
  /// `showScrollToBottomButton`을 `true`로 설정합니다.
  void _scrollListener() {
    // `reverse: true`이므로 `minScrollExtent`가 리스트의 맨 아래(최신 메시지)를 의미합니다.
    // 사용자가 맨 아래에서 100픽셀 이상 스크롤하면 버튼을 표시합니다.
    if (scrollController.position.pixels >
        scrollController.position.minScrollExtent + 100) {
      if (!showScrollToBottomButton) {
        setState(() => showScrollToBottomButton = true);
      }
    } else {
      if (showScrollToBottomButton) {
        setState(() => showScrollToBottomButton = false);
      }
    }
  }

  /// 스크롤을 맨 아래(최신 메시지 위치)로 부드럽게 이동시킵니다.
  void scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}
