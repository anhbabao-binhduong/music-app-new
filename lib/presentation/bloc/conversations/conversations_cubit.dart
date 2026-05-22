import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/chat_repository.dart';
import 'conversations_state.dart';

class ConversationsCubit extends Cubit<ConversationsState> {
  final ChatRepository _repo;
  StreamSubscription<void>? _sub;

  ConversationsCubit({required ChatRepository chatRepository})
      : _repo = chatRepository,
        super(const ConversationsInitial());

  Future<void> init() async {
    emit(const ConversationsLoading());
    await _loadConversations();

    // Subscribe to realtime updates
    _sub = _repo.subscribeToConversationUpdates().listen((_) {
      _loadConversations();
    });
  }

  Future<void> _loadConversations() async {
    final result = await _repo.getConversations();
    result.fold(
      (failure) => emit(ConversationsError(message: failure.toString())),
      (conversations) {
        print('[Conv] loaded ${conversations.length} conversations');
        emit(ConversationsLoaded(conversations: conversations));
      },
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _repo.disposeConversationsChannel();
    return super.close();
  }
}