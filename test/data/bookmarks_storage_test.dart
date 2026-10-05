import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_trial/data/bookmarks_storage.dart';
import 'package:flutter_trial/models/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> sessionJson(String id) => {
  'id': id,
  'title': 'Session $id',
  'startTime': '2026-10-14T10:30:00',
  'endTime': '2026-10-14T11:15:00',
  'tags': ['AI'],
};

Future<List<Session>> loadWith(Object? storedValue) {
  SharedPreferences.setMockInitialValues({
    SharedPrefsBookmarksStorage.storageKey: ?storedValue,
  });
  return SharedPrefsBookmarksStorage().load();
}

void main() {
  group('SharedPrefsBookmarksStorage', () {
    test('saves and loads sessions without losing fields', () async {
      SharedPreferences.setMockInitialValues({});
      final original = Session.fromJson(sessionJson('1'));

      await SharedPrefsBookmarksStorage().save([original]);
      final loaded = await SharedPrefsBookmarksStorage().load();

      expect(loaded, hasLength(1));
      expect(loaded.first.toJson(), original.toJson());
    });

    test('returns an empty list when nothing is saved', () async {
      expect(await loadWith(null), isEmpty);
    });

    test('returns an empty list when the stored value is corrupted', () async {
      expect(await loadWith('{not json'), isEmpty);
      expect(await loadWith(jsonEncode({'id': '1'})), isEmpty);
    });

    test('skips unreadable entries and keeps the rest', () async {
      final stored = jsonEncode([
        sessionJson('1'),
        {'id': '2'}, // missing title and startTime
        'not an object',
        sessionJson('3'),
      ]);

      final loaded = await loadWith(stored);

      expect([for (final s in loaded) s.id], ['1', '3']);
    });
  });
}
