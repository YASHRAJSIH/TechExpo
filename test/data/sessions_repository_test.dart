import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_trial/data/sessions_api.dart';
import 'package:flutter_trial/data/sessions_exception.dart';
import 'package:flutter_trial/data/sessions_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> sessionJson(String id, {String start = '10:00'}) => {
  'id': id,
  'title': 'Session $id',
  'startTime': '2026-10-14T$start:00',
};

SessionsRepository repositoryWith(
  MockClientHandler handler, {
  Duration timeout = const Duration(seconds: 10),
}) {
  return SessionsRepository(
    api: SessionsApi(client: MockClient(handler), timeout: timeout),
  );
}

SessionsRepository repositoryReturning(String body, {int status = 200}) =>
    repositoryWith((_) async => http.Response(body, status));

void main() {
  group('SessionsRepository.fetchSessions', () {
    test('returns sessions sorted by start time', () async {
      final repository = repositoryReturning(
        jsonEncode({
          'sessions': [
            sessionJson('b', start: '12:00'),
            sessionJson('a', start: '09:00'),
          ],
        }),
      );

      final sessions = await repository.fetchSessions();

      expect(sessions.map((s) => s.id), ['a', 'b']);
    });

    test('accepts a bare list as well as {"sessions": [...]}', () async {
      final repository = repositoryReturning(jsonEncode([sessionJson('1')]));

      final sessions = await repository.fetchSessions();

      expect(sessions, hasLength(1));
    });

    test('skips broken items but keeps the valid ones', () async {
      final repository = repositoryReturning(
        jsonEncode({
          'sessions': [
            sessionJson('1'),
            {'id': '2'}, // missing title and startTime
            'not an object',
            null,
            sessionJson('1'), // duplicate id
            sessionJson('3'),
          ],
        }),
      );

      final sessions = await repository.fetchSessions();

      expect(sessions.map((s) => s.id), ['1', '3']);
    });

    test('returns an empty list for an empty array', () async {
      final repository = repositoryReturning(jsonEncode({'sessions': []}));

      expect(await repository.fetchSessions(), isEmpty);
    });

    test('throws InvalidDataException for broken JSON', () {
      final repository = repositoryReturning('{"sessions": [');

      expect(repository.fetchSessions(), throwsA(isA<InvalidDataException>()));
    });

    test('throws InvalidDataException when the shape is wrong', () {
      final repository = repositoryReturning(jsonEncode({'data': 'oops'}));

      expect(repository.fetchSessions(), throwsA(isA<InvalidDataException>()));
    });

    test('throws ServerException with the status code on a 500', () {
      final repository = repositoryReturning('Internal error', status: 500);

      expect(
        repository.fetchSessions(),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'status', 500),
        ),
      );
    });

    test('throws NoInternetException when offline', () {
      final repository = repositoryWith(
        (_) => throw const SocketException('Failed host lookup'),
      );

      expect(repository.fetchSessions(), throwsA(isA<NoInternetException>()));
    });

    test('throws RequestTimeoutException when the server is too slow', () {
      final repository = repositoryWith(
        (_) => Completer<http.Response>().future, // never completes
        timeout: const Duration(milliseconds: 10),
      );

      expect(
        repository.fetchSessions(),
        throwsA(isA<RequestTimeoutException>()),
      );
    });
  });
}
