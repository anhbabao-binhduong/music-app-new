import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:music_app/core/errors/failures.dart';
import 'package:music_app/data/models/chat_message_model.dart';
import 'package:music_app/domain/entities/chat_conversation_entity.dart';
import 'package:music_app/domain/entities/chat_message_entity.dart';
import 'package:music_app/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final SupabaseClient _supabase;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<ChatMessageEntity>> _controllers = {};

  ChatRepositoryImpl({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  @override
  Future<Either<Failure, String>> findOrCreateConversation(
      String otherUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser!.id;
      // Lưu UUID nhỏ hơn làm participant_1 để đúng UNIQUE constraint
      final p1 = currentUserId.compareTo(otherUserId) < 0
          ? currentUserId
          : otherUserId;
      final p2 = currentUserId.compareTo(otherUserId) < 0
          ? otherUserId
          : currentUserId;

      // Tìm cuộc hội thoại đã tồn tại
      final existing = await _supabase
          .from('chat_conversations')
          .select('id')
          .eq('participant_1_id', p1)
          .eq('participant_2_id', p2)
          .maybeSingle();

      if (existing != null) {
        return Right(existing['id'] as String);
      }

      // Tạo cuộc hội thoại mới
      final created = await _supabase
          .from('chat_conversations')
          .insert({
            'participant_1_id': p1,
            'participant_2_id': p2,
          })
          .select('id')
          .single();

      return Right(created['id'] as String);
    } catch (e) {
      return Left(CacheFailure('Không thể tạo cuộc hội thoại: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
    String conversationId, {
    DateTime? cursor,
  }) async {
    try {
      var query = _supabase
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId);

      if (cursor != null) {
        query = query.lt('created_at', cursor.toIso8601String());
      }

      final response =
          await query.order('created_at', ascending: false).limit(30);

      final messages = (response as List)
          .map((e) => ChatMessageModel.fromJson(
                  Map<String, dynamic>.from(e as Map))
              .toEntity())
          .toList();

      return Right(messages);
    } catch (e) {
      return Left(CacheFailure('Không thể tải tin nhắn: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage(
    String conversationId,
    String content,
  ) async {
    try {
      final currentUserId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('chat_messages')
          .insert(ChatMessageModel.toInsertJson(
            conversationId: conversationId,
            senderId: currentUserId,
            content: content,
          ))
          .select()
          .single();

      final message =
          ChatMessageModel.fromJson(Map<String, dynamic>.from(response))
              .toEntity();
      return Right(message);
    } catch (e) {
      return Left(CacheFailure('Không thể gửi tin nhắn: $e'));
    }
  }

  @override
  Stream<ChatMessageEntity> subscribeToMessages(String conversationId) {
    // Nếu đã có controller cho conversation này thì trả về stream cũ
    if (_controllers.containsKey(conversationId)) {
      return _controllers[conversationId]!.stream;
    }

    final controller = StreamController<ChatMessageEntity>.broadcast();
    _controllers[conversationId] = controller;

    final channel = _supabase.channel('chat:$conversationId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (PostgresChangePayload payload) {
        final newRecord = payload.newRecord;
        final message = ChatMessageModel.fromJson(
          Map<String, dynamic>.from(newRecord),
        ).toEntity();
        controller.add(message);
      },
    );
    channel.subscribe();
    _channels[conversationId] = channel;

    return controller.stream;
  }

  @override
  Future<void> disposeChannel(String conversationId) async {
    await _channels[conversationId]?.unsubscribe();
    _channels.remove(conversationId);
    await _controllers[conversationId]?.close();
    _controllers.remove(conversationId);
  }

  // ── Conversations list ────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ChatConversationEntity>>>
      getConversations() async {
    try {
      final uid = _supabase.auth.currentUser!.id;

      // Lấy tất cả cuộc hội thoại mà user tham gia
      final rows = await _supabase
          .from('chat_conversations')
          .select('id, participant_1_id, participant_2_id, last_message_at')
          .or('participant_1_id.eq.$uid,participant_2_id.eq.$uid')
          .order('last_message_at', ascending: false, nullsFirst: false);

      final List<ChatConversationEntity> conversations = [];

      for (final row in rows) {
        final convId = row['id'] as String;
        final p1 = row['participant_1_id'] as String;
        final p2 = row['participant_2_id'] as String;
        final otherUserId = (p1 == uid) ? p2 : p1;

        // Lấy profile người kia
        final profile = await _supabase
            .from('profiles')
            .select('name, avatar_url')
            .eq('id', otherUserId)
            .maybeSingle();

        final otherUserName =
            (profile?['name'] as String?) ?? 'Người dùng';
        final otherUserAvatarUrl = profile?['avatar_url'] as String?;

        // Lấy tin nhắn cuối cùng
        final lastMsg = await _supabase
            .from('chat_messages')
            .select('content')
            .eq('conversation_id', convId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        final lastMessagePreview = lastMsg?['content'] as String?;
        final lastMessageAt = row['last_message_at'] != null
            ? DateTime.tryParse(row['last_message_at'] as String)?.toLocal()
            : null;

        // Lấy số tin nhắn chưa đọc từ người khác trong cuộc hội thoại này
        final unreadResult = await _supabase
            .from('chat_messages')
            .select()
            .eq('conversation_id', convId)
            .neq('sender_id', uid)
            .eq('is_read', false)
            .count(CountOption.exact);
        final unreadCount = unreadResult.count;

        conversations.add(ChatConversationEntity(
          id: convId,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserAvatarUrl: otherUserAvatarUrl,
          lastMessageAt: lastMessageAt,
          lastMessagePreview: lastMessagePreview,
          unreadCount: unreadCount,
        ));
      }

      return Right(conversations);
    } catch (e) {
      return Left(CacheFailure('Không thể tải danh sách hội thoại: $e'));
    }
  }

  @override
  Stream<void> subscribeToConversationUpdates() {
    final uid = _supabase.auth.currentUser!.id;
    final channelKey = 'conversations:$uid';
    final msgsChannelKey = 'conversations_msgs:$uid';

    if (_convStreamController != null) {
      return _convStreamController!.stream;
    }

    final controller = StreamController<void>.broadcast();

    final channel = _supabase.channel(channelKey);
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'chat_conversations',
      callback: (PostgresChangePayload payload) {
        // Chỉ emit nếu user là participant
        final newRecord = payload.newRecord;
        if (newRecord.isNotEmpty) {
          final p1 = newRecord['participant_1_id'] as String?;
          final p2 = newRecord['participant_2_id'] as String?;
          if (p1 == uid || p2 == uid) {
            controller.add(null);
          }
        } else {
          // Trường hợp update/delete
          controller.add(null);
        }
      },
    );
    channel.subscribe();
    _channels[channelKey] = channel;

    final msgsChannel = _supabase.channel(msgsChannelKey);
    msgsChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'chat_messages',
      callback: (PostgresChangePayload payload) {
        controller.add(null);
      },
    );
    msgsChannel.subscribe();
    _channels[msgsChannelKey] = msgsChannel;

    // Lưu controller riêng cho conversations stream
    // Dùng key đặc biệt để không trùng với chat controllers
    _convStreamController = controller;

    return controller.stream;
  }

  StreamController<void>? _convStreamController;

  @override
  Future<void> disposeConversationsChannel() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final channelKey = 'conversations:$uid';
    final msgsChannelKey = 'conversations_msgs:$uid';
    await _channels[channelKey]?.unsubscribe();
    _channels.remove(channelKey);
    await _channels[msgsChannelKey]?.unsubscribe();
    _channels.remove(msgsChannelKey);
    await _convStreamController?.close();
    _convStreamController = null;
  }

  @override
  Future<void> markConversationRead(String conversationId) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;

      debugPrint(
        '[ChatRepositoryImpl] markConversationRead conversationId=$conversationId uid=$uid',
      );

      final result = await _supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', uid)
          .eq('is_read', false)
          .select();

      debugPrint(
        '[ChatRepositoryImpl] markConversationRead updatedRows=${(result as List).length} raw=$result',
      );
    } catch (e, st) {
      debugPrint('[ChatRepositoryImpl] markConversationRead error: $e');
      debugPrint('[ChatRepositoryImpl] markConversationRead stack: $st');
    }
  }
}
