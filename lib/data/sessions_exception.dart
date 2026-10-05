/// Every way loading sessions can fail. The repository converts raw
/// exceptions into one of these, so the UI only ever sees [message].
sealed class SessionsException implements Exception {
  const SessionsException(this.message);

  /// Short, user-friendly text shown on screen.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NoInternetException extends SessionsException {
  const NoInternetException()
    : super('No internet connection. Check your network and try again.');
}

class RequestTimeoutException extends SessionsException {
  const RequestTimeoutException()
    : super('The server is taking too long to respond. Please try again.');
}

class ServerException extends SessionsException {
  const ServerException(this.statusCode)
    : super(
        'The server returned an error ($statusCode). Please try again '
        'later.',
      );

  final int statusCode;
}

class InvalidDataException extends SessionsException {
  const InvalidDataException()
    : super('We received data we couldn\'t read. Please try again later.');
}

class UnknownSessionsException extends SessionsException {
  const UnknownSessionsException()
    : super('Something went wrong. Please try again.');
}
