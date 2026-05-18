import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user_search_result_entity.dart';
import '../repositories/user_repository.dart';

class SearchUsersUsecase {
  final UserRepository repository;
  SearchUsersUsecase(this.repository);

  Future<Either<Failure, List<UserSearchResultEntity>>> call(String query) =>
      repository.searchUsers(query);
}