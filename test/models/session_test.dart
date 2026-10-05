import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_trial/models/session.dart';

Map<String, dynamic> validJson() => {
  'id': '1',
  'title': 'AI Agents',
  'category': 'Keynote',
  'speaker': 'Anna Müller',
  'speakerRole': 'Engineer',
  'startTime': '2026-10-14T10:30:00',
  'endTime': '2026-10-14T11:15:00',
  'hall': 'Hall A',
  'room': 'Stage 2',
  'description': 'About agents.',
  'tags': ['AI', 'Agents'],
};

void main() {
  group('Session.fromJson', () {
    test('parses a complete session', () {
      final session = Session.fromJson(validJson());

      expect(session.id, '1');
      expect(session.title, 'AI Agents');
      expect(session.startTime, DateTime(2026, 10, 14, 10, 30));
      expect(session.endTime, DateTime(2026, 10, 14, 11, 15));
      expect(session.location, 'Hall A - Stage 2');
      expect(session.tags, ['AI', 'Agents']);
    });

    test('accepts a numeric id', () {
      final session = Session.fromJson(validJson()..['id'] = 42);
      expect(session.id, '42');
    });

    test('trims whitespace from strings', () {
      final session = Session.fromJson(validJson()..['title'] = '  AI  ');
      expect(session.title, 'AI');
    });

    for (final field in ['id', 'title', 'startTime']) {
      test('throws when required "$field" is missing', () {
        expect(
          () => Session.fromJson(validJson()..remove(field)),
          throwsFormatException,
        );
      });
    }

    test('throws when title is blank', () {
      expect(
        () => Session.fromJson(validJson()..['title'] = '   '),
        throwsFormatException,
      );
    });

    test('throws when startTime is not a valid date', () {
      expect(
        () => Session.fromJson(validJson()..['startTime'] = 'tomorrow'),
        throwsFormatException,
      );
    });

    test('uses fallbacks for missing optional fields', () {
      final session = Session.fromJson({
        'id': 1,
        'title': 'Minimal',
        'startTime': '2026-10-14T10:30:00',
      });

      expect(session.speaker, Session.fallback);
      expect(session.hall, Session.fallback);
      expect(session.category, 'General');
      expect(session.endTime, isNull);
      expect(session.description, isEmpty);
      expect(session.tags, isEmpty);
      expect(session.location, Session.fallback);
    });

    test('uses fallbacks when optional fields have the wrong type', () {
      final session = Session.fromJson(
        validJson()
          ..['speaker'] = {'name': 'Anna'}
          ..['hall'] = null
          ..['endTime'] = 12345
          ..['tags'] = 'AI',
      );

      expect(session.speaker, Session.fallback);
      expect(session.hall, Session.fallback);
      expect(session.endTime, isNull);
      expect(session.tags, isEmpty);
    });

    test('drops invalid entries from tags', () {
      final session = Session.fromJson(
        validJson()
          ..['tags'] = [
            'AI',
            null,
            3,
            '',
            {'x': 1},
          ],
      );
      expect(session.tags, ['AI', '3']);
    });

    test('ignores an endTime that is before startTime', () {
      final session = Session.fromJson(
        validJson()..['endTime'] = '2026-10-14T09:00:00',
      );
      expect(session.endTime, isNull);
    });
  });

  group('Session.statusAt', () {
    final session = Session.fromJson(validJson());

    test('is upcoming before the start', () {
      expect(
        session.statusAt(DateTime(2026, 10, 14, 10, 0)),
        SessionStatus.upcoming,
      );
    });

    test('is live between start and end', () {
      expect(
        session.statusAt(DateTime(2026, 10, 14, 10, 45)),
        SessionStatus.live,
      );
    });

    test('is completed after the end', () {
      expect(
        session.statusAt(DateTime(2026, 10, 14, 12, 0)),
        SessionStatus.completed,
      );
    });
  });
}
