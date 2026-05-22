import 'package:equatable/equatable.dart';
import 'package:music_app/domain/entities/chat_message_entity.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessageEntity> messages; // newest first
  final bool hasMore;
  final bool isSending;
  final bool isLoadingMore;
  final String? errorMessage;

  const ChatLoaded({
    required this.messages,
    this.hasMore = true,
    this.isSending = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  ChatLoaded copyWith({
    List<ChatMessageEntity>? messages,
    bool? hasMore,
    bool? isSending,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      isSending: isSending ?? this.isSending,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [messages, hasMore, isSending, isLoadingMore, errorMessage];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object?> get props => [message];
}