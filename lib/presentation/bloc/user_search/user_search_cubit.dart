import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/search_users_usecase.dart';
import 'user_search_state.dart';

class UserSearchCubit extends Cubit<UserSearchState> {
  final SearchUsersUsecase _searchUsersUsecase;

  Timer? _debounce;

  UserSearchCubit({required SearchUsersUsecase searchUsersUsecase})
      : _searchUsersUsecase = searchUsersUsecase,
        super(const UserSearchInitial());

  void onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      emit(const UserSearchInitial());
      return;
    }

    emit(const UserSearchLoading());
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(trimmed);
    });
  }

  Future<void> _search(String query) async {
    final result = await _searchUsersUsecase(query);
    result.fold(
      (failure) => emit(UserSearchError(failure.message)),
      (users) {
        if (users.isEmpty) {
          emit(const UserSearchEmpty());
        } else {
          emit(UserSearchLoaded(users));
        }
      },
    );
  }

  void reset() {
    _debounce?.cancel();
    emit(const UserSearchInitial());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}