import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/notification_model.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final SupabaseClient _supabase;

  NotificationCubit()
      : _supabase = Supabase.instance.client,
        super(NotificationInitial());

  Future<void> loadNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      emit(const NotificationError('Chưa đăng nhập'));
      return;
    }

    emit(NotificationLoading());
    try {
      final res = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final notifications = (res as List)
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      emit(NotificationLoaded(notifications));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    try {
      // Optimistic update
      final updatedList = currentState.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      emit(NotificationLoaded(updatedList));

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      // Ignore or revert
    }
  }

  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Optimistic update
      final updatedList = currentState.notifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();
      emit(NotificationLoaded(updatedList));

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      // Ignore or revert
    }
  }
}
