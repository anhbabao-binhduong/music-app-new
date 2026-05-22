// lib/domain/entities/chat_message_entity.dart
import 'package:equatable/equatable.dart';

class ChatMessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  /// Optimistic messages have a temporary ID prefixed with 'temp_'
  bool get isOptimistic => id.startsWith('temp_');

  @override
  List<Object?> get props =>
      [id, conversationId, senderId, content, createdAt, isRead];
}