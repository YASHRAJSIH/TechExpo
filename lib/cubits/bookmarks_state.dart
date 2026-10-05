import '../models/session.dart';

class BookmarksState {
  const BookmarksState({this.sessions = const []});

  /// Bookmarked sessions, sorted by start time.
  final List<Session> sessions;

  bool isBookmarked(String sessionId) => sessions.any((s) => s.id == sessionId);
}
