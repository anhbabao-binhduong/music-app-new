// lib/domain/entities/category_entity.dart

import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String  id;
  final String  name;
  final String  slug;
  final String  emoji;
  final String  color;
  final String? description;
  final String? coverImageUrl;
  final int     displayOrder;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.emoji,
    required this.color,
    this.description,
    this.coverImageUrl,
    required this.displayOrder,
  });

  @override
  List<Object?> get props =>
      [id, name, slug, emoji, color, description, coverImageUrl, displayOrder];
}