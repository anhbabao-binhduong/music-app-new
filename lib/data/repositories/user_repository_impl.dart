import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/user_search_result_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_search_result_model.dart';

class UserRepositoryImpl implements UserRepository {
  final SupabaseClient _client;

  UserRepositoryImpl(this._client);

  static const List<String> _profileColumnCandidates = [
    'id',
    'name',
    'display_name',
    'username',
    'avatar_url',
    'bio',
    'location',
    'website_url',
    'email',
  ];

  static final RegExp _emailRegex = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    caseSensitive: false,
  );

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  Set<String>? _availableProfileColumns;

  Future<Set<String>> _getAvailableProfileColumns() async {
    if (_availableProfileColumns != null) {
      return _availableProfileColumns!;
    }

    final availableColumns = <String>{};

    for (final column in _profileColumnCandidates) {
      try {
        await _client.from('profiles').select(column).limit(1);
        availableColumns.add(column);
      } on PostgrestException {
        // Bỏ qua cột không tồn tại trong schema hiện tại.
      }
    }

    availableColumns.add('id');
    _availableProfileColumns = availableColumns;
    return availableColumns;
  }

  String _buildSelectColumns(Set<String> availableColumns) {
    return _profileColumnCandidates
        .where(availableColumns.contains)
        .join(', ');
  }

  String _escapeLikeValue(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_')
        .replaceAll(',', r'\,');
  }

  bool _isEmailKeyword(String value) => _emailRegex.hasMatch(value);

  bool _isUuidKeyword(String value) => _uuidRegex.hasMatch(value);

  @override
  Future<Either<Failure, List<UserSearchResultEntity>>> searchUsers(
      String query) async {
    try {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        return const Right([]);
      }

      final availableColumns = await _getAvailableProfileColumns();
      final selectColumns = _buildSelectColumns(availableColumns);
      final keyword = _escapeLikeValue(trimmed);
      final pattern = '%$keyword%';
      final filters = <String>[];

      if (availableColumns.contains('name')) {
        filters.add('name.ilike.$pattern');
      }
      if (availableColumns.contains('display_name')) {
        filters.add('display_name.ilike.$pattern');
      }
      if (availableColumns.contains('username')) {
        filters.add('username.ilike.$pattern');
      }
      if (_isEmailKeyword(trimmed) && availableColumns.contains('email')) {
        filters.add('email.ilike.$pattern');
      }
      if (_isUuidKeyword(trimmed)) {
        filters.add('id.eq.$trimmed');
      }

      if (filters.isEmpty) {
        return const Right([]);
      }

      final rows = await _client
          .from('profiles')
          .select(selectColumns)
          .or(filters.join(','))
          .limit(20);

      final results =
          rows.map((r) => UserSearchResultModel.fromMap(r)).toList();
      return Right(results);
    } on PostgrestException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserSearchResultEntity>> getUserProfileById(
      String userId) async {
    try {
      final availableColumns = await _getAvailableProfileColumns();
      final selectColumns = _buildSelectColumns(availableColumns);
      final row = await _client
          .from('profiles')
          .select(selectColumns)
          .eq('id', userId)
          .maybeSingle();

      if (row == null) {
        return const Left(NotFoundFailure('Không tìm thấy người dùng'));
      }
      return Right(UserSearchResultModel.fromMap(row));
    } on PostgrestException catch (e) {
      return Left(UnknownFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

}
