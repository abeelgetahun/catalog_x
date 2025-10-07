import '../errors/failures.dart';

class ErrorMessage {
  static const generic = 'Something went wrong. Please try again later.';
  static const network =
      'You appear to be offline. Check your internet connection.';
  static const timeout = 'Request took too long. Please retry.';
  static const server =
      'We had trouble contacting the server. Please try again soon.';
  static const cache =
      'We couldn\'t load saved data. Pull to refresh to try again.';
}

String mapFailureToMessage(Failure failure) {
  if (failure is NetworkFailure) return ErrorMessage.network;
  if (failure is CacheFailure) return ErrorMessage.cache;
  if (failure is ServerFailure) return ErrorMessage.server;
  return failure.displayMessage;
}

String mapErrorToMessage(Object error) {
  if (error is Failure) return mapFailureToMessage(error);
  return ErrorMessage.generic;
}
