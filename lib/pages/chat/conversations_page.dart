import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/router/app_routes.dart';
import '../../domain/entities/chat_conversation_entity.dart';
import '../../presentation/bloc/conversations/conversations_cubit.dart';
import '../../presentation/bloc/conversations/conversations_state.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ConversationsCubit>()..init(),
      child: const _ConversationsView(),
    );
  }
}

class _ConversationsView extends StatelessWidget {
  const _ConversationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
      ),
      body: BlocBuilder<ConversationsCubit, ConversationsState>(
        builder: (context, state) {
          if (state is ConversationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ConversationsError) {
            return Center(
              child: Text(
                'Đã xảy ra lỗi: ${state.message}',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }
          if (state is ConversationsLoaded) {
            if (state.conversations.isEmpty) {
              return const Center(
                child: Text(
                  'Chưa có tin nhắn nào',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: state.conversations.length,
              itemBuilder: (context, index) {
                return _ConversationTile(
                  conversation: state.conversations[index],
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversationEntity conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: conversation.otherUserAvatarUrl != null &&
                conversation.otherUserAvatarUrl!.isNotEmpty
            ? NetworkImage(conversation.otherUserAvatarUrl!)
            : null,
        backgroundColor: kAccent.withValues(alpha: 0.2),
        child: conversation.otherUserAvatarUrl == null ||
                conversation.otherUserAvatarUrl!.isEmpty
            ? Text(
                _initials(conversation.otherUserName),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kAccent,
                ),
              )
            : null,
      ),
      title: Text(
        conversation.otherUserName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: conversation.lastMessagePreview != null
          ? Text(
              conversation.lastMessagePreview!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnread ? Colors.white70 : Colors.grey,
                fontSize: 13,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastMessageAt != null)
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: TextStyle(
                color: hasUnread ? kAccent : Colors.grey,
                fontSize: 12,
              ),
            ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () async {
        await Navigator.of(context).pushNamed(
          AppRoutes.chat,
          arguments: {
            'conversationId': conversation.id,
            'otherUserName': conversation.otherUserName,
          },
        );

        if (context.mounted) {
          context.read<ConversationsCubit>().init();
        }
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}