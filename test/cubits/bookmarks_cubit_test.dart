import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_trial/cubits/bookmarks_cubit.dart';
import 'package:flutter_trial/data/bookmarks_storage.dart';
import 'package:flutter_trial/models/session.dart';

class InMemoryBookmarksStorage implements BookmarksStorage {
  InMemoryBookmarksStorage([List<Session> initial = const []])
    : saved = List.of(initial);

  List<Session> saved;
  bool failOnSave = false;

  @override
  Future<List<Session>> load() async => List.of(saved);

  @override
  Future<void> save(List<Session> sessions) async {
    if (failOnSave) throw Exception('disk full');
    saved = List.of(sessions);
  }
}

Session session(String id, {int hour = 10, String hall = 'Hall A'}) =>
    Session.fromJson({
      'id': id,
      'title': 'Session $id',
      'startTime': DateTime(2026, 10, 14, hour).toIso8601String(),
      'hall': hall,
    });

List<String> ids(List<Session> sessions) => [for (final s in sessions) s.id];

void main() {
  group('BookmarksCubit', () {
    test('toggle adds a session, keeps them sorted and saves', () async {
      final storage = InMemoryBookmarksStorage();
      final cubit = BookmarksCubit(storage);

      await cubit.toggle(session('late', hour: 15));
      await cubit.toggle(session('early', hour: 9));

      expect(ids(cubit.state.sessions), ['early', 'late']);
      expect(cubit.state.isBookmarked('late'), isTrue);
      expect(ids(storage.saved), ['early', 'late']);
    });

    test('toggling twice removes the bookmark', () async {
      final storage = InMemoryBookmarksStorage();
      final cubit = BookmarksCubit(storage);

      await cubit.toggle(session('1'));
      await cubit.toggle(session('1'));

      expect(cubit.state.sessions, isEmpty);
      expect(cubit.state.isBookmarked('1'), isFalse);
      expect(storage.saved, isEmpty);
    });

    test('bookmarks survive a restart', () async {
      final storage = InMemoryBookmarksStorage();
      await BookmarksCubit(storage).toggle(session('1'));

      // A new cubit with the same storage acts like a restarted app.
      final restarted = BookmarksCubit(storage);
      await restarted.load();

      expect(ids(restarted.state.sessions), ['1']);
    });

    test('load keeps bookmarks added before it finished', () async {
      final storage = InMemoryBookmarksStorage([session('saved', hour: 9)]);
      final cubit = BookmarksCubit(storage);

      final loading = cubit.load();
      await cubit.toggle(session('new', hour: 11));
      await loading;

      expect(ids(cubit.state.sessions), ['saved', 'new']);
      expect(ids(storage.saved), ['saved', 'new']);
    });

    test('updateFrom refreshes saved copies and keeps missing ones', () async {
      final storage = InMemoryBookmarksStorage([
        session('1', hall: 'Hall A'),
        session('gone'),
      ]);
      final cubit = BookmarksCubit(storage);
      await cubit.load();

      await cubit.updateFrom([session('1', hall: 'Hall C'), session('other')]);

      expect(ids(cubit.state.sessions), ['1', 'gone']);
      expect(cubit.state.sessions.first.hall, 'Hall C');
      expect(storage.saved.first.hall, 'Hall C');
    });

    test('a failed save keeps the bookmark in memory', () async {
      final storage = InMemoryBookmarksStorage()..failOnSave = true;
      final cubit = BookmarksCubit(storage);

      await cubit.toggle(session('1'));

      expect(cubit.state.isBookmarked('1'), isTrue);
    });
  });
}
