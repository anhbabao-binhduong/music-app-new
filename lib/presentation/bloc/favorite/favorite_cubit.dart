import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteCubit extends Cubit<List<String>> {
  final SupabaseClient _supabase = Supabase.instance.client;

  FavoriteCubit() : super([]) {
    _loadFavorites();
    _supabase.auth.onAuthStateChange.listen((_) {
      _loadFavorites();
    });
  }

  String? get _uid => _supabase.auth.currentUser?.id;

  Future<void> _loadFavorites() async {
    final uid = _uid;
    if (uid == null) {
      emit([]);
      return;
    }

    try {
      final response = await _supabase
          .from('favorites')
          .select('song_id')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final ids = (response as List)
          .map((row) => row['song_id']?.toString())
          .whereType<String>()
          .toList();

      emit(ids);
    } catch (e) {
      emit([]);
    }
  }

  Future<void> toggleFavorite(String songId) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('Bạn cần đăng nhập để dùng yêu thích');
    }

    final isLiked = state.contains(songId);

    try {
      if (isLiked) {
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', uid)
            .eq('song_id', songId);
      } else {
        await _supabase.from('favorites').insert({
          'user_id': uid,
          'song_id': songId,
        });
      }

      await _loadFavorites();
    } catch (e) {
      rethrow;
    }
  }
}
