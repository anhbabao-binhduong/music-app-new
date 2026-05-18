import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user_search_result_entity.dart';
import '../repositories/user_repository.dart';

class GetUserProfileUsecase {
  final UserRepository repository;
  GetUserProfileUsecase(this.repository);

  Future<Either<Failure, UserSearchResultEntity>> call(String userId) =>
      repository.getUserProfileById(userId);
}