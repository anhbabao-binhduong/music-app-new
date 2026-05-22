// lib/domain/repositories/chat_repository.dart
import 'package:dartz/dartz.dart';
import 'package:music_app/core/errors/failures.dart';
import 'package:music_app/domain/entities/chat_conversation_entity.dart';
import 'package:music_app/domain/entities/chat_message_entity.dart';

abstract class ChatRepository {
  Future<Either<Failure, String>> findOrCreateConversation(String otherUserId);

  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
    String conversationId, {
    DateTime? cursor,
  });

  Future<Either<Failure, ChatMessageEntity>> sendMessage(
    String conversationId,
    String content,
  );

  Stream<ChatMessageEntity> subscribeToMessages(String conversationId);

  Future<void> disposeChannel(String conversationId);

  Future<Either<Failure, List<ChatConversationEntity>>> getConversations();

  Stream<void> subscribeToConversationUpdates();

  Future<void> disposeConversationsChannel();

  Future<void> markConversationRead(String conversationId);
}
