import 'package:flutter/material.dart';
import 'package:my_chat_app/models/message.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/chat_provider.dart';
import 'package:my_chat_app/providers/profile_provider.dart';
import 'package:my_chat_app/models/profile.dart';
import 'package:my_chat_app/chat_message.dart';

/// 채팅방의 메시지 목록을 표시하는 위젯입니다.
///
/// `ChatProvider`로부터 메시지 목록을 받아와 `ChatMessage` 위젯으로 변환하여 보여줍니다.
/// 검색 모드와 일반 모드를 구분하여 다른 목록을 표시할 수 있습니다.
/// 무한 스크롤을 지원하여 이전 메시지를 계속 불러올 수 있습니다.
class MessageList extends StatelessWidget {
  /// 메시지 목록의 스크롤을 제어하는 컨트롤러입니다.
  final ScrollController scrollController;

  /// 검색 필드가 표시되는지 여부입니다.
  final bool showSearchField;

  /// 현재 검색어입니다.
  final String searchText;

  /// {@template message_list}
  /// `MessageList` 위젯을 생성합니다.
  /// {@endtemplate}
  const MessageList({
    super.key,
    required this.scrollController,
    required this.showSearchField,
    required this.searchText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final profileProvider = context.watch<ProfileProvider>();
        final colorScheme = Theme.of(context).colorScheme;

        // 에러 또는 로딩 상태 처리
        if (chatProvider.error != null) {
          return Center(child: Text('오류: ${chatProvider.error}'));
        }
        if (!chatProvider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }
        if (chatProvider.messages.isEmpty && !chatProvider.isLoadingMore) {
          return const Center(child: Text('대화를 시작해보세요!'));
        }

        final messages = chatProvider.messages;
        final searchResults = chatProvider.searchResults;

        // 조건부 UI 렌더링: 검색 모드 vs 일반 모드
        if (showSearchField && searchResults.isNotEmpty) {
          // 검색 결과가 있을 경우, 검색 결과 목록을 표시
          return ListView.builder(
            key: const ValueKey('searchListView'),
            controller: scrollController,
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final message = searchResults[index];
              return _buildMessageItem(
                  context, profileProvider, chatProvider, message);
            },
          );
        } else if (showSearchField &&
            searchResults.isEmpty &&
            searchText.isNotEmpty) {
          // 검색을 했지만 결과가 없을 경우
          return const Center(child: Text('검색 결과가 없습니다.'));
        } else {
          // 일반 채팅 메시지 목록 표시
          return ListView.builder(
            key: const ValueKey('chatListView'),
            controller: scrollController,
            reverse: true, // 최신 메시지가 하단에 오도록 설정
            itemCount: messages.length + (chatProvider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // 무한 스크롤 로딩 인디케이터
              if (chatProvider.isLoadingMore && index == messages.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  ),
                );
              }
              final message = messages[index];
              return _buildMessageItem(
                  context, profileProvider, chatProvider, message);
            },
          );
        }
      },
    );
  }

  /// 개별 메시지 항목을 구성하는 헬퍼 메서드입니다.
  ///
  /// [message] 표시할 `Message` 객체입니다.
  ///
  /// 메시지 발신자의 프로필 정보를 비동기적으로 가져와 `ChatMessage` 위젯에 전달합니다.
  Widget _buildMessageItem(
    BuildContext context,
    ProfileProvider profileProvider,
    ChatProvider chatProvider,
    Message message,
  ) {
    final isMe = message.localUserId != null &&
        message.localUserId == profileProvider.currentLocalUserId;

    return FutureBuilder<Profile?>(
      // 발신자 ID로 프로필 정보를 가져옵니다.
      future: message.localUserId == null
          ? Future.value(null)
          : profileProvider.getProfileById(message.localUserId!),
      builder: (context, profileSnapshot) {
        final Profile? senderProfile = profileSnapshot.data;
        return ChatMessage(
          message: message,
          isMe: isMe,
          myLocalUserId: profileProvider.currentLocalUserId ?? '',
          senderNickname: message.localUserId == null
              ? '탈퇴한 사용자'
              : (senderProfile?.nickname ?? '알 수 없음'),
          avatarUrl: message.localUserId == null
              ? null
              : (isMe
                  ? profileProvider.currentProfile?.avatarUrl
                  : senderProfile?.avatarUrl),
          isOnline: message.localUserId == null
              ? false
              : (senderProfile?.isOnline ?? false),
          lastSeen:
              message.localUserId == null ? null : senderProfile?.lastSeen,
          onDelete: isMe && !message.isDeleted
              ? () => chatProvider.deleteMessage(message.id)
              : null,
        );
      },
    );
  }
}
