import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_search_result_entity.dart';

abstract class UserSearchState extends Equatable {
  const UserSearchState();

  @override
  List<Object?> get props => [];
}

class UserSearchInitial extends UserSearchState {
  const UserSearchInitial();
}

class UserSearchLoading extends UserSearchState {
  const UserSearchLoading();
}

class UserSearchLoaded extends UserSearchState {
  final List<UserSearchResultEntity> users;

  const UserSearchLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class UserSearchEmpty extends UserSearchState {
  const UserSearchEmpty();
}

class UserSearchError extends UserSearchState {
  final String message;

  const UserSearchError(this.message);

  @override
  List<Object?> get props => [message];
}