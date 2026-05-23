import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:music_app/core/di/service_locator.dart';
import 'package:music_app/core/router/app_routes.dart';
import 'package:music_app/presentation/bloc/chat/chat_cubit.dart';
import 'package:music_app/presentation/bloc/chat/chat_state.dart';
import 'package:music_app/widgets/chat/chat_input_bar.dart';
import 'package:music_app/widgets/chat/chat_message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserId;
  final String? otherUserAvatarUrl;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserId,
    this.otherUserAvatarUrl,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  late final String _currentUserId;
  late final ChatCubit _chatCubit;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser!.id;
    _chatCubit = getIt<ChatCubit>(
      param1: widget.conversationId,
      param2: _currentUserId,
    )..init();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = _chatCubit.state;
      if (state is ChatLoaded && state.hasMore && !state.isLoadingMore) {
        _chatCubit.loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chatCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatCubit>.value(
      value: _chatCubit,
      child: BlocListener<ChatCubit, ChatState>(
        listener: (context, state) {
          if (state is ChatLoaded && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage!,
                  style: GoogleFonts.dmSans(color: Colors.white),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            titleSpacing: 0,
            title: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.userProfile,
                  arguments: widget.otherUserId,
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: widget.otherUserAvatarUrl != null &&
                            widget.otherUserAvatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: widget.otherUserAvatarUrl!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Text(
                                widget.otherUserName.isNotEmpty
                                    ? widget.otherUserName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.syne(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              errorWidget: (_, __, ___) => Text(
                                widget.otherUserName.isNotEmpty
                                    ? widget.otherUserName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.syne(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            widget.otherUserName.isNotEmpty
                                ? widget.otherUserName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.syne(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.otherUserName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Đang hoạt động',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.68),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: BlocBuilder<ChatCubit, ChatState>(
                  builder: (context, state) {
                    if (state is ChatLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state is ChatError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () =>
                                    context.read<ChatCubit>().init(),
                                child: Text(
                                  'Thử lại',
                                  style: GoogleFonts.syne(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is ChatLoaded) {
                      final messages = state.messages;

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.24),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Hãy bắt đầu cuộc trò chuyện',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: 0.52),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        itemCount:
                            messages.length + (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }

                          final message = messages[index];
                          final isMe = message.senderId == _currentUserId;
                          final isSameAsNext =
                              index < messages.length - 1 &&
                              messages[index + 1].senderId == message.senderId;

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: isSameAsNext ? 4 : 12,
                            ),
                            child: ChatMessageBubble(
                              key: ValueKey(message.id),
                              message: message,
                              isMe: isMe,
                            ),
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
              BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  final isSending =
                      state is ChatLoaded ? state.isSending : false;
                  return ChatInputBar(
                    isSending: isSending,
                    onSend: (content) =>
                        context.read<ChatCubit>().sendMessage(content),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}