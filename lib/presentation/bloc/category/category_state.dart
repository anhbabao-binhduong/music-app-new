// lib/presentation/bloc/category/category_state.dart

import 'package:equatable/equatable.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/song_entity.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

class CategoryLoaded extends CategoryState {
  final List<CategoryEntity> categories;
  final List<SongEntity>     songs;
  final String?              selectedSlug; // null = "Tất cả"

  const CategoryLoaded({
    required this.categories,
    required this.songs,
    this.selectedSlug,
  });

  CategoryLoaded copyWith({
    List<CategoryEntity>? categories,
    List<SongEntity>?     songs,
    String?               selectedSlug,
    bool                  clearSlug = false,
  }) =>
      CategoryLoaded(
        categories:   categories   ?? this.categories,
        songs:        songs        ?? this.songs,
        selectedSlug: clearSlug ? null : (selectedSlug ?? this.selectedSlug),
      );

  @override
  List<Object?> get props => [categories, songs, selectedSlug];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);
  @override
  List<Object?> get props => [message];
}