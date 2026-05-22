import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/di/service_locator.dart';
import 'package:music_app/domain/entities/chat_message_entity.dart';
import 'package:music_app/domain/repositories/chat_repository.dart';
import 'package:music_app/presentation/bloc/chat/chat_state.dart';
import 'package:music_app/services/chat_notification_service.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repo;
  final String conversationId;
  final String currentUserId;

  StreamSubscription<ChatMessageEntity>? _sub;

  ChatCubit({
    required ChatRepository repo,
    required this.conversationId,
    required this.currentUserId,
  })  : _repo = repo,
        super(ChatInitial());

  /// Tải lịch sử tin nhắn rồi lắng nghe Realtime
  Future<void> init() async {
    emit(ChatLoading());
    final result = await _repo.getMessages(conversationId);
    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (messages) {
        emit(ChatLoaded(
          messages: messages,
          hasMore: messages.length >= 30,
        ));
        _markRead();
        _subscribeToRealtime();
      },
    );
  }

  Future<void> _markRead() async {
    await _repo.markConversationRead(conversationId);
    getIt<ChatNotificationService>().refresh();
  }

  void _subscribeToRealtime() {
    _sub = _repo.subscribeToMessages(conversationId).listen(_onRealtimeMessage);
  }

  void _onRealtimeMessage(ChatMessageEntity incoming) {
    final current = state;
    if (current is! ChatLoaded) return;

    final messages = List<ChatMessageEntity>.from(current.messages);

    // Kiểm tra xem tin nhắn đã tồn tại chưa (tránh trùng lặp)
    final alreadyExists = messages.any((m) => m.id == incoming.id);
    if (alreadyExists) return;

    // Nếu là tin nhắn của mình gửi: xóa tin nhắn optimistic trùng nội dung
    final tempIndex = messages.indexWhere(
      (m) =>
          m.isOptimistic &&
          m.senderId == incoming.senderId &&
          m.content == incoming.content,
    );
    if (tempIndex != -1) {
      messages.removeAt(tempIndex);
    }

    // Thêm tin nhắn thật vào đầu danh sách (newest first)
    messages.insert(0, incoming);
    emit(current.copyWith(messages: messages));

    if (incoming.senderId != currentUserId) {
      _markRead();
    }
  }

  /// Gửi tin nhắn với optimistic update
  Future<void> sendMessage(String content) async {
    final current = state;
    if (current is! ChatLoaded || content.trim().isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = ChatMessageEntity(
      id: tempId,
      conversationId: conversationId,
      senderId: currentUserId,
      content: content.trim(),
      createdAt: DateTime.now(),
      isRead: false,
    );

    // Thêm tin nhắn tạm vào đầu danh sách
    final updatedMessages = [optimisticMessage, ...current.messages];
    emit(current.copyWith(messages: updatedMessages, isSending: true));

    final result = await _repo.sendMessage(conversationId, content.trim());
    result.fold(
      (failure) {
        // Xóa tin nhắn optimistic khi có lỗi
        final currentLoaded = state;
        if (currentLoaded is ChatLoaded) {
          final rollback = currentLoaded.messages
              .where((m) => m.id != tempId)
              .toList();
          emit(currentLoaded.copyWith(
            messages: rollback,
            isSending: false,
            errorMessage: failure.message,
          ));
        }
      },
      (_) {
        // Tin nhắn thật sẽ đến qua Realtime subscription — không thêm thủ công
        final currentLoaded = state;
        if (currentLoaded is ChatLoaded) {
          emit(currentLoaded.copyWith(isSending: false));
        }
      },
    );
  }

  /// Tải thêm tin nhắn cũ hơn (cursor pagination)
  Future<void> loadMore() async {
    final current = state;
    if (current is! ChatLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final oldest = current.messages.isNotEmpty ? current.messages.last : null;
    final cursor = oldest?.createdAt;

    final result = await _repo.getMessages(conversationId, cursor: cursor);
    result.fold(
      (failure) {
        // Giữ state hiện tại, không crash khi load more thất bại
        emit(current.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        ));
      },
      (older) {
        final merged = [...current.messages, ...older];
        emit(current.copyWith(
          messages: merged,
          hasMore: older.length >= 30,
          isLoadingMore: false,
          errorMessage: null,
        ));
      },
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _repo.disposeChannel(conversationId);
    return super.close();
  }
}