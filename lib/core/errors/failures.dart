import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  @override List<Object> get props => [message];
}

class CacheFailure    extends Failure { const CacheFailure(super.m); }
class NetworkFailure  extends Failure { const NetworkFailure(super.m); }
class NotFoundFailure extends Failure { const NotFoundFailure(super.m); }
class UnknownFailure  extends Failure { const UnknownFailure(super.m); }