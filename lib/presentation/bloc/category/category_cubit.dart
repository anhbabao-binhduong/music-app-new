// lib/presentation/bloc/category/category_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_categories_usecase.dart';
import '../../../domain/usecases/get_songs_by_category_usecase.dart';
import 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  final GetCategoriesUseCase      _getCategories;
  final GetSongsByCategoryUseCase _getSongsByCategory;

  CategoryCubit({
    required GetCategoriesUseCase      getCategories,
    required GetSongsByCategoryUseCase getSongsByCategory,
  })  : _getCategories      = getCategories,
        _getSongsByCategory = getSongsByCategory,
        super(const CategoryInitial());

  /// Gọi lần đầu khi Home mở
  Future<void> loadAll() async {
    emit(const CategoryLoading());

    final catResult  = await _getCategories();
    final songResult = await _getSongsByCategory(null); // null = tất cả

    catResult.fold(
      (failure) => emit(CategoryError(failure.message)),
      (categories) => songResult.fold(
        (failure) => emit(CategoryError(failure.message)),
        (songs)   => emit(CategoryLoaded(
          categories: categories,
          songs: songs,
          allSongs: songs, // lúc đầu chưa filter → allSongs = songs
        )),
      ),
    );
  }

  /// Gọi khi user tap chip — tap lại chip đang chọn → bỏ chọn (về "Tất cả")
  Future<void> selectCategory(String? slug) async {
    final current = state;
    if (current is! CategoryLoaded) return;

    final newSlug = (current.selectedSlug == slug) ? null : slug;

    // Cập nhật selectedSlug ngay (chip highlight liền tay)
    emit(current.copyWith(selectedSlug: newSlug, clearSlug: newSlug == null));

    final result = await _getSongsByCategory(newSlug);
    result.fold(
      (failure) => emit(CategoryError(failure.message)),
      (songs) {
        // Lấy state mới nhất (tránh race condition)
        final latest = state;
        if (latest is CategoryLoaded) {
          // Chỉ cập nhật songs (filtered), giữ nguyên allSongs
          emit(latest.copyWith(songs: songs));
        }
      },
    );
  }
}