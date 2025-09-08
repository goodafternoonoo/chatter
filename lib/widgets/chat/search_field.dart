import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/chat_provider.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

/// 채팅 메시지를 검색하기 위한 입력 필드 위젯입니다.
///
/// 사용자가 검색어를 입력하고 검색 버튼을 누르거나 키보드에서 '완료'를 누르면,
/// `ChatProvider`의 `searchMessages` 메서드를 호출하여 검색을 실행합니다.
class SearchField extends StatelessWidget {
  /// 검색어 입력을 제어하는 컨트롤러입니다.
  final TextEditingController searchController;

  /// 검색 필드의 포커스를 관리하는 노드입니다.
  final FocusNode searchFocusNode;

  /// {@template search_field}
  /// `SearchField` 위젯을 생성합니다.
  /// {@endtemplate}
  const SearchField({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacingMedium),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              decoration: InputDecoration(
                hintText: '검색어를 입력하세요',
                // 검색어 삭제 버튼
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    // 검색어를 지웠을 때 검색 결과도 초기화
                    context.read<ChatProvider>().searchMessages('');
                  },
                ),
              ),
              // 키보드에서 '완료' 액션을 했을 때 검색 실행
              onSubmitted: (value) {
                final chatProvider = context.read<ChatProvider>();
                chatProvider.searchMessages(value);
                searchFocusNode.requestFocus(); // 검색 후에도 포커스 유지
              },
            ),
          ),
          const SizedBox(width: UIConstants.spacingSmall),
          // 검색 실행 버튼
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              final chatProvider = context.read<ChatProvider>();
              chatProvider.searchMessages(searchController.text);
            },
          ),
        ],
      ),
    );
  }
}
