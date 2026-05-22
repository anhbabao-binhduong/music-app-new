import 'package:equatable/equatable.dart';

import '../../../domain/entities/chat_conversation_entity.dart';

sealed class ConversationsState extends Equatable {
  const ConversationsState();

  @override
  List<Object?> get props => [];
}

class ConversationsInitial extends ConversationsState {
  const ConversationsInitial();
}

class ConversationsLoading extends ConversationsState {
  const ConversationsLoading();
}

class ConversationsLoaded extends ConversationsState {
  final List<ChatConversationEntity> conversations;

  const ConversationsLoaded({required this.conversations});

  @override
  List<Object?> get props => [conversations];
}

class ConversationsError extends ConversationsState {
  final String message;

  const ConversationsError({required this.message});

  @override
  List<Object?> get props => [message];
}