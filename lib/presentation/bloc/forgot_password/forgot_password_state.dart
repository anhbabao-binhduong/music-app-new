import 'package:equatable/equatable.dart';

abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

class ForgotPasswordEmailSent extends ForgotPasswordState {
  final String email;

  const ForgotPasswordEmailSent(this.email);

  @override
  List<Object?> get props => [email];
}

class ForgotPasswordError extends ForgotPasswordState {
  final String message;

  const ForgotPasswordError(this.message);

  @override
  List<Object?> get props => [message];
}

class ResetPasswordLoading extends ForgotPasswordState {
  const ResetPasswordLoading();
}

class ResetPasswordSuccess extends ForgotPasswordState {
  const ResetPasswordSuccess();
}

class ResetPasswordError extends ForgotPasswordState {
  final String message;

  const ResetPasswordError(this.message);

  @override
  List<Object?> get props => [message];
}