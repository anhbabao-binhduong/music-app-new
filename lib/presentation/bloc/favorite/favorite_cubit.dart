import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteCubit extends Cubit<List<String>> {
  final _supabase = Supabase.instance.client;
  
  // Biến này để lắng nghe trạng thái đăng nhập
  StreamSubscription? _authSub;

  FavoriteCubit() : super([]) {
    // Tự động lắng nghe Firebase: Đăng nhập thì tải nhạc, đăng xuất thì xóa sạch UI
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadFavoritesFromDB(user.uid);
      } else {
        emit([]); // User đăng xuất -> Xóa danh sách trên màn hình
      }
    });
  }

  Future<void> _loadFavoritesFromDB(String uid) async {
    try {
      final response = await _supabase
          .from('favorites')
          .select('song_id')
          .eq('user_id', uid);

      final List<String> savedIds = (response as List).map((row) => row['song_id'] as String).toList();
      emit(savedIds);
    } catch (e) {
      print('Lỗi tải yêu thích từ DB: $e');
    }
  }

  Future<void> toggleFavorite(String songId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentFavorites = List<String>.from(state);
    final isLiked = currentFavorites.contains(songId);

    // 1. Cập nhật UI ngay lập tức cho mượt
    if (isLiked) {
      currentFavorites.remove(songId);
    } else {
      currentFavorites.add(songId);
    }
    emit(currentFavorites);

    // 2. Đồng bộ ngầm với Supabase
    try {
      if (isLiked) {
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', user.uid)
            .eq('song_id', songId);
      } else {
        // DÙNG UPSERT: Nếu bài hát đã có trong DB thì bỏ qua lỗi, nếu chưa có thì thêm mới
        await _supabase
            .from('favorites')
            .upsert({
              'user_id': user.uid,
              'song_id': songId
            }, onConflict: 'user_id, song_id'); 
      }
    } catch (e) {
      print('Lỗi đồng bộ DB: $e');
    }
  }

  // Đừng quên đóng stream khi Cubit bị hủy để tránh tràn bộ nhớ
  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}