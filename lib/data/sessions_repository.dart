import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/session.dart';
import 'sessions_api.dart';
import 'sessions_exception.dart';

class SessionsRepository {
  SessionsRepository({SessionsApi? api}) : _api = api ?? SessionsApi();

  final SessionsApi _api;

  /// Loads all sessions, sorted by start time.
  ///
  /// Throws only [SessionsException]. Invalid items are skipped and logged
  /// instead of failing the whole list.
  Future<List<Session>> fetchSessions() async {
    final http.Response response;
    try {
      response = await _api.fetchSessions();
    } on SocketException {
      throw const NoInternetException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NoInternetException();
    } catch (error, stack) {
      _log('Unexpected network error', error, stack);
      throw const UnknownSessionsException();
    }

    if (response.statusCode != 200) {
      throw ServerException(response.statusCode);
    }

    return parseSessions(response.body);
  }

  /// Parses the response body. Accepts `{"sessions": [...]}` or a bare list.
  static List<Session> parseSessions(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (error, stack) {
      _log('Response is not valid JSON', error, stack);
      throw const InvalidDataException();
    }

    final items = switch (decoded) {
      {'sessions': final List<dynamic> list} => list,
      final List<dynamic> list => list,
      _ => null,
    };
    if (items == null) {
      _log('Unexpected JSON shape: ${decoded.runtimeType}');
      throw const InvalidDataException();
    }

    final sessions = <Session>[];
    final seenIds = <String>{};
    for (final (index, item) in items.indexed) {
      try {
        if (item is! Map<String, dynamic>) {
          throw FormatException('Item is not an object', item);
        }
        final session = Session.fromJson(item);
        if (!seenIds.add(session.id)) {
          throw FormatException('Duplicate id ${session.id}');
        }
        sessions.add(session);
      } on FormatException catch (error) {
        _log('Skipping session at index $index: ${error.message}');
      }
    }

    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    return List.unmodifiable(sessions);
  }

  static void _log(String message, [Object? error, StackTrace? stack]) {
    developer.log(
      message,
      name: 'SessionsRepository',
      error: error,
      stackTrace: stack,
    );
  }
}
