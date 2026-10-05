import '../models/session.dart';

sealed class SessionsState {
  const SessionsState();
}

class SessionsLoading extends SessionsState {
  const SessionsLoading();
}

class SessionsLoaded extends SessionsState {
  const SessionsLoaded(this.sessions, {this.refreshError});

  final List<Session> sessions;

  /// Set when a refresh failed; [sessions] still holds the previous data.
  final String? refreshError;
}

class SessionsEmpty extends SessionsState {
  const SessionsEmpty();
}

class SessionsError extends SessionsState {
  const SessionsError(this.message);

  final String message;
}
