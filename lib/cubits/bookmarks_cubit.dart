import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/bookmarks_storage.dart';
import '../models/session.dart';
import 'bookmarks_state.dart';

class BookmarksCubit extends Cubit<BookmarksState> {
  BookmarksCubit(this._storage) : super(const BookmarksState());

  final BookmarksStorage _storage;

  /// Restores saved bookmarks. Anything bookmarked before loading finished
  /// is kept as well.
  Future<void> load() async {
    final saved = await _storage.load();
    if (isClosed) return;

    final byId = {for (final s in saved) s.id: s};
    for (final s in state.sessions) {
      byId[s.id] = s;
    }
    _emitSorted(byId.values);
    if (byId.length != saved.length) await _save();
  }

  /// Adds the session if it isn't bookmarked, removes it otherwise.
  Future<void> toggle(Session session) async {
    if (state.isBookmarked(session.id)) {
      await remove(session.id);
    } else {
      _emitSorted([...state.sessions, session]);
      await _save();
    }
  }

  Future<void> remove(String sessionId) async {
    _emitSorted(state.sessions.where((s) => s.id != sessionId));
    await _save();
  }

  /// Replaces saved copies with fresh data from the API (e.g. a changed
  /// time or room). Bookmarks missing from [fresh] are kept as they are.
  Future<void> updateFrom(List<Session> fresh) async {
    if (state.sessions.isEmpty) return;
    final freshById = {for (final s in fresh) s.id: s};
    _emitSorted(state.sessions.map((s) => freshById[s.id] ?? s));
    await _save();
  }

  void _emitSorted(Iterable<Session> sessions) {
    final sorted = sessions.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    emit(BookmarksState(sessions: List.unmodifiable(sorted)));
  }

  /// A failed save keeps the in-memory state; the next change retries.
  Future<void> _save() async {
    try {
      await _storage.save(state.sessions);
    } catch (error, stack) {
      developer.log(
        'Could not save bookmarks',
        name: 'BookmarksCubit',
        error: error,
        stackTrace: stack,
      );
    }
  }
}
