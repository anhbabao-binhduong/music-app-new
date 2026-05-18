import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_user_profile_usecase.dart';
import 'user_profile_state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  final GetUserProfileUsecase _getUserProfileUsecase;

  UserProfileCubit({required GetUserProfileUsecase getUserProfileUsecase})
      : _getUserProfileUsecase = getUserProfileUsecase,
        super(const UserProfileInitial());

  Future<void> loadUserProfile(String userId) async {
    emit(const UserProfileLoading());

    final result = await _getUserProfileUsecase(userId);
    result.fold(
      (failure) => emit(UserProfileError(failure.message)),
      (user) => emit(UserProfileLoaded(user)),
    );
  }
}