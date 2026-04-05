// lib/domain/usecases/get_categories_usecase.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/category_entity.dart';
import '../repositories/music_repository.dart';

class GetCategoriesUseCase {
  final MusicRepository _repository;
  const GetCategoriesUseCase(this._repository);

  Future<Either<Failure, List<CategoryEntity>>> call() =>
      _repository.getCategories();
}