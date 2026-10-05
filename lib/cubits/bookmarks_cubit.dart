import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/session.dart';
import 'bookmarks_state.dart';

class BookmarksCubit extends Cubit<BookmarksState> {
  BookmarksCubit() : super(const BookmarksState());

  /// Adds the session if it isn't bookmarked, removes it otherwise.
  void toggle(Session session) {
    if (state.isBookmarked(session.id)) {
      remove(session.id);
    } else {
      final sessions = [...state.sessions, session]
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      emit(BookmarksState(sessions: List.unmodifiable(sessions)));
    }
  }

  void remove(String sessionId) {
    final sessions = state.sessions.where((s) => s.id != sessionId).toList();
    emit(BookmarksState(sessions: List.unmodifiable(sessions)));
  }
}
