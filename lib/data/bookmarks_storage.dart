import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';

/// Saves bookmarked sessions on the device.
///
/// Full sessions are stored (not just ids) so the Bookmarks page works
/// offline, even when the sessions request fails.
abstract interface class BookmarksStorage {
  Future<List<Session>> load();

  Future<void> save(List<Session> sessions);
}

class SharedPrefsBookmarksStorage implements BookmarksStorage {
  SharedPrefsBookmarksStorage({Future<SharedPreferences>? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance();

  static const storageKey = 'bookmarked_sessions_v1';

  final Future<SharedPreferences> _prefs;

  /// Never throws. Unreadable entries are skipped; if the whole value is
  /// corrupted an empty list is returned.
  @override
  Future<List<Session>> load() async {
    try {
      final raw = (await _prefs).getString(storageKey);
      if (raw == null) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _log('Stored bookmarks are not a list, ignoring them');
        return const [];
      }

      final sessions = <Session>[];
      for (final item in decoded) {
        try {
          if (item is Map<String, dynamic>) {
            sessions.add(Session.fromJson(item));
          }
        } on FormatException catch (error) {
          _log('Skipping stored bookmark: ${error.message}');
        }
      }
      return sessions;
    } catch (error, stack) {
      _log('Could not read bookmarks', error, stack);
      return const [];
    }
  }

  @override
  Future<void> save(List<Session> sessions) async {
    final raw = jsonEncode([for (final s in sessions) s.toJson()]);
    await (await _prefs).setString(storageKey, raw);
  }

  static void _log(String message, [Object? error, StackTrace? stack]) {
    developer.log(
      message,
      name: 'BookmarksStorage',
      error: error,
      stackTrace: stack,
    );
  }
}
