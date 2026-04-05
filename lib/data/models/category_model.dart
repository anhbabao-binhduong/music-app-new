// lib/data/models/category_model.dart

import '../../domain/entities/category_entity.dart';

class CategoryModel {
  final String  id;
  final String  name;
  final String  slug;
  final String  emoji;
  final String  color;
  final String? description;
  final String? coverImageUrl;
  final int     displayOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.emoji,
    required this.color,
    this.description,
    this.coverImageUrl,
    required this.displayOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id:            json['id']              as String,
        name:          json['name']            as String,
        slug:          json['slug']            as String,
        emoji:         (json['emoji']          as String?) ?? '🎵',
        color:         (json['color']          as String?) ?? '#534AB7',
        description:   json['description']     as String?,
        coverImageUrl: json['cover_image_url'] as String?,
        displayOrder:  (json['display_order']  as int?)    ?? 0,
      );

  CategoryEntity toEntity() => CategoryEntity(
        id:            id,
        name:          name,
        slug:          slug,
        emoji:         emoji,
        color:         color,
        description:   description,
        coverImageUrl: coverImageUrl,
        displayOrder:  displayOrder,
      );
}