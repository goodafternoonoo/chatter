import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/chat_provider.dart';
import 'package:my_chat_app/constants/ui_constants.dart';

class SearchField extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                  },
                ),
              ),
              onSubmitted: (value) {
                final chatProvider = context.read<ChatProvider>();
                chatProvider.searchMessages(value);
                searchFocusNode.requestFocus(); // 검색 후 포커스 유지
              },
            ),
          ),
          const SizedBox(width: UIConstants.spacingSmall),
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
