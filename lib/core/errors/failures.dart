import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  String get displayMessage => message.isEmpty
      ? 'Something went wrong. Please try again later.'
      : message;

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([
    String message =
        'We had trouble contacting the server. Please try again soon.',
  ]) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([
    String message =
        'We couldn\'t load saved data. Pull to refresh to try again.',
  ]) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    String message =
        'You appear to be offline. Check your internet connection.',
  ]) : super(message);
}
