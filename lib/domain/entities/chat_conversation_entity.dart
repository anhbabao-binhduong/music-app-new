// lib/domain/entities/chat_conversation_entity.dart
import 'package:equatable/equatable.dart';

class ChatConversationEntity extends Equatable {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;

  const ChatConversationEntity({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        otherUserId,
        otherUserName,
        otherUserAvatarUrl,
        lastMessageAt,
        lastMessagePreview,
        unreadCount,
      ];
}
