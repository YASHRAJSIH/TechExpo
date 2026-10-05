import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_trial/cubits/sessions_cubit.dart';
import 'package:flutter_trial/cubits/sessions_state.dart';
import 'package:flutter_trial/data/sessions_exception.dart';
import 'package:flutter_trial/data/sessions_repository.dart';
import 'package:flutter_trial/models/session.dart';

/// Returns the queued results in order: a `List<Session>` or an exception.
class FakeSessionsRepository extends SessionsRepository {
  FakeSessionsRepository(this.results);

  final List<Object> results;

  @override
  Future<List<Session>> fetchSessions() async {
    final result = results.removeAt(0);
    if (result is SessionsException) throw result;
    return result as List<Session>;
  }
}

final session = Session.fromJson({
  'id': '1',
  'title': 'AI Agents',
  'startTime': '2026-10-14T10:30:00',
});

void main() {
  group('SessionsCubit', () {
    test('starts in the loading state', () {
      final cubit = SessionsCubit(FakeSessionsRepository([]));
      expect(cubit.state, isA<SessionsLoading>());
    });

    test('emits Loaded when sessions arrive', () async {
      final cubit = SessionsCubit(
        FakeSessionsRepository([
          [session],
        ]),
      );

      await cubit.load();

      final state = cubit.state;
      expect(state, isA<SessionsLoaded>());
      expect((state as SessionsLoaded).sessions, [session]);
      expect(state.refreshError, isNull);
    });

    test('emits Empty when the list is empty', () async {
      final cubit = SessionsCubit(FakeSessionsRepository([<Session>[]]));

      await cubit.load();

      expect(cubit.state, isA<SessionsEmpty>());
    });

    test('emits Error with a friendly message on first-load failure', () async {
      final cubit = SessionsCubit(
        FakeSessionsRepository([const NoInternetException()]),
      );

      await cubit.load();

      expect(
        cubit.state,
        isA<SessionsError>().having(
          (s) => s.message,
          'message',
          const NoInternetException().message,
        ),
      );
    });

    test('keeps old data when a refresh fails', () async {
      final cubit = SessionsCubit(
        FakeSessionsRepository([
          [session],
          const ServerException(500),
        ]),
      );

      await cubit.load();
      await cubit.load();

      final state = cubit.state;
      expect(state, isA<SessionsLoaded>());
      expect((state as SessionsLoaded).sessions, [session]);
      expect(state.refreshError, const ServerException(500).message);
    });

    test('retry after an error can succeed', () async {
      final cubit = SessionsCubit(
        FakeSessionsRepository([
          const RequestTimeoutException(),
          [session],
        ]),
      );

      await cubit.load();
      expect(cubit.state, isA<SessionsError>());

      await cubit.load();
      expect(cubit.state, isA<SessionsLoaded>());
    });
  });
}
