import 'package:flutter/material.dart';

mixin ScrollControllerMixin<T extends StatefulWidget> on State<T> {
  final ScrollController scrollController = ScrollController();
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

  void _scrollListener() {
    // 사용자가 최신 메시지(스크롤의 맨 아래)에서 벗어났을 때 버튼을 표시
    // reverse: true 이므로 minScrollExtent가 최신 메시지 위치
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

  void scrollToBottom() {
    if (!scrollController.hasClients) return;
    // reverse: true 이므로 minScrollExtent가 최신 메시지 위치
    scrollController.animateTo(
      scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}
