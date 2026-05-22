import 'package:music_app/domain/entities/chat_message_entity.dart';

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  ChatMessageEntity toEntity() => ChatMessageEntity(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        createdAt: createdAt,
        isRead: isRead,
      );

  static Map<String, dynamic> toInsertJson({
    required String conversationId,
    required String senderId,
    required String content,
  }) =>
      {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
      };
}