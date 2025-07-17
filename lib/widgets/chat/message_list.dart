import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_chat_app/providers/chat_provider.dart';
import 'package:my_chat_app/providers/profile_provider.dart';
import 'package:my_chat_app/models/profile.dart';
import 'package:my_chat_app/chat_message.dart';

class MessageList extends StatelessWidget {
  final ScrollController scrollController;
  final bool showSearchField;
  final String searchText;

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

        if (showSearchField && searchResults.isNotEmpty) {
          return ListView.builder(
            key: const ValueKey('searchListView'),
            controller: scrollController,
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final message = searchResults[index];
              final isMe =
                  message.localUserId != null &&
                  message.localUserId == profileProvider.currentLocalUserId;

              return FutureBuilder<Profile?>(
                future: message.localUserId == null
                    ? Future.value(null)
                    : profileProvider.getProfileById(message.localUserId!),
                builder: (context, profileSnapshot) {
                  final Profile? senderProfile = profileSnapshot.data;
                  return ChatMessage(
                    message: message,
                    isMe: isMe,
                    myLocalUserId: profileProvider.currentLocalUserId ?? '',
                    senderNickname: message.localUserId == null ? '탈퇴한 사용자' : (senderProfile?.nickname ?? '알 수 없음'),
                    avatarUrl: message.localUserId == null
                        ? null
                        : (isMe
                            ? profileProvider.currentProfile?.avatarUrl
                            : senderProfile?.avatarUrl),
                    isOnline: message.localUserId == null ? false : (senderProfile?.isOnline ?? false),
                    lastSeen: message.localUserId == null ? null : senderProfile?.lastSeen,
                    onDelete: isMe && !message.isDeleted
                        ? () => chatProvider.deleteMessage(message.id)
                        : null,
                  );
                },
              );
            },
          );
        } else if (showSearchField &&
            searchResults.isEmpty &&
            searchText.isNotEmpty) {
          return const Center(child: Text('검색 결과가 없습니다.'));
        } else {
          return ListView.builder(
            key: const ValueKey('chatListView'),
            controller: scrollController,
            reverse: true,
            itemCount: messages.length + (chatProvider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
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
              final isMe =
                  message.localUserId != null &&
                  message.localUserId == profileProvider.currentLocalUserId;

              return FutureBuilder<Profile?>(
                future: message.localUserId == null
                    ? Future.value(null)
                    : profileProvider.getProfileById(message.localUserId!),
                builder: (context, profileSnapshot) {
                  final Profile? senderProfile = profileSnapshot.data;
                  return ChatMessage(
                    message: message,
                    isMe: isMe,
                    myLocalUserId: profileProvider.currentLocalUserId ?? '',
                    senderNickname: message.localUserId == null ? '탈퇴한 사용자' : (senderProfile?.nickname ?? '알 수 없음'),
                    avatarUrl: message.localUserId == null
                        ? null
                        : (isMe
                            ? profileProvider.currentProfile?.avatarUrl
                            : senderProfile?.avatarUrl),
                    isOnline: message.localUserId == null ? false : (senderProfile?.isOnline ?? false),
                    lastSeen: message.localUserId == null ? null : senderProfile?.lastSeen,
                    onDelete: isMe && !message.isDeleted
                        ? () => chatProvider.deleteMessage(message.id)
                        : null,
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}
