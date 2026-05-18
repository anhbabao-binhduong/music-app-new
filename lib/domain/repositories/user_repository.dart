import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user_search_result_entity.dart';

abstract class UserRepository {
  /// Tìm kiếm user theo tên, ID hoặc email.
  Future<Either<Failure, List<UserSearchResultEntity>>> searchUsers(
      String query);

  /// Lấy profile chi tiết của một user theo ID.
  Future<Either<Failure, UserSearchResultEntity>> getUserProfileById(
      String userId);
}