import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service quản lý thông báo tin nhắn chưa đọc.
/// Dùng Supabase Realtime thay vì polling.
class ChatNotificationService {
  final SupabaseClient _supabase;
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  final Map<String, RealtimeChannel> _channels = {};

  ChatNotificationService({required SupabaseClient supabase})
      : _supabase = supabase;

  /// Bắt đầu lắng nghe tin nhắn mới qua Realtime
  void startListening() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    // Fetch initial count
    _fetchUnreadCount();

    // Listen INSERT trên chat_messages (tin nhắn mới từ người khác)
    final insertKey = 'unread:$uid';
    if (!_channels.containsKey(insertKey)) {
      final insertChannel = _supabase.channel(insertKey);
      insertChannel
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'chat_messages',
            callback: (payload) {
              final row = payload.newRecord;
              // Chỉ đếm tin nhắn từ người khác
              if (row['sender_id'] != uid) {
                _fetchUnreadCount();
              }
            },
          )
          .subscribe();
      _channels[insertKey] = insertChannel;
    }

    // Listen UPDATE trên chat_messages (đánh dấu đã đọc)
    final readKey = 'read:$uid';
    if (!_channels.containsKey(readKey)) {
      final readChannel = _supabase.channel(readKey);
      readChannel
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'chat_messages',
            callback: (payload) {
              _fetchUnreadCount();
            },
          )
          .subscribe();
      _channels[readKey] = readChannel;
    }
  }

  Future<void> refresh() async => await _fetchUnreadCount();

  Future<void> _fetchUnreadCount() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;

      debugPrint('[ChatNotificationService] _fetchUnreadCount uid=$uid');

      // 1. Fetch user's active conversation ids
      final conversations = await _supabase
          .from('chat_conversations')
          .select('id')
          .or('participant_1_id.eq.$uid,participant_2_id.eq.$uid');

      debugPrint(
          '[ChatNotificationService] conversations raw=$conversations');

      final convIds = (conversations as List)
          .map((c) => c['id'] as String)
          .toList();

      debugPrint('[ChatNotificationService] convIds=$convIds');

      if (convIds.isEmpty) {
        unreadCount.value = 0;
        debugPrint(
            '[ChatNotificationService] convIds empty -> unreadCount=0');
        return;
      }

      // 2. Count unread messages inside these conversations
      final result = await _supabase
          .from('chat_messages')
          .select()
          .inFilter('conversation_id', convIds)
          .neq('sender_id', uid)
          .eq('is_read', false)
          .count(CountOption.exact);

      debugPrint('[ChatNotificationService] unread query raw=$result');
      debugPrint(
          '[ChatNotificationService] unread count=${result.count} (before set value=${unreadCount.value})');

      unreadCount.value = result.count;
      debugPrint(
          '[ChatNotificationService] unreadCount updated -> ${unreadCount.value}');
    } catch (e, st) {
      debugPrint('[ChatNotificationService] _fetchUnreadCount error: $e');
      debugPrint('[ChatNotificationService] _fetchUnreadCount stack: $st');
    }
  }

  /// Dừng lắng nghe và giải phóng channels
  Future<void> disposeChannels() async {
    for (final entry in _channels.entries) {
      await _supabase.removeChannel(entry.value);
    }
    _channels.clear();
  }

  /// Gọi khi user logout
  Future<void> dispose() async {
    await disposeChannels();
    unreadCount.value = 0;
  }
}