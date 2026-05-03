import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/services/supabase_auth_service.dart';

import 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final SupabaseAuthService _authService;

  ForgotPasswordCubit(this._authService) : super(const ForgotPasswordInitial());

  Future<void> sendResetEmail(String email) async {
    emit(const ForgotPasswordLoading());
    try {
      await _authService.resetPasswordForEmail(email.trim());
      emit(ForgotPasswordEmailSent(email.trim()));
    } catch (error) {
      emit(ForgotPasswordError(_authService.mapError(error)));
    }
  }

  Future<void> resendResetEmail(String email) async {
    await sendResetEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    emit(const ResetPasswordLoading());
    try {
      await _authService.updatePassword(newPassword);
      emit(const ResetPasswordSuccess());
    } catch (error) {
      emit(ResetPasswordError(_authService.mapError(error)));
    }
  }

  void resetState() {
    emit(const ForgotPasswordInitial());
  }
}