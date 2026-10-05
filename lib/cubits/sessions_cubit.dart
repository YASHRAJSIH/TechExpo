import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/sessions_exception.dart';
import '../data/sessions_repository.dart';
import 'sessions_state.dart';

class SessionsCubit extends Cubit<SessionsState> {
  SessionsCubit(this._repository) : super(const SessionsLoading());

  final SessionsRepository _repository;
  bool _isFetching = false;

  /// Loads sessions. If data is already on screen and the request fails,
  /// the old data stays and [SessionsLoaded.refreshError] is set.
  Future<void> load() async {
    if (_isFetching) return;
    _isFetching = true;

    final previous = state;
    if (previous is! SessionsLoaded) emit(const SessionsLoading());

    try {
      final sessions = await _repository.fetchSessions();
      if (isClosed) return;
      emit(sessions.isEmpty ? const SessionsEmpty() : SessionsLoaded(sessions));
    } on SessionsException catch (error) {
      if (isClosed) return;
      emit(
        previous is SessionsLoaded
            ? SessionsLoaded(previous.sessions, refreshError: error.message)
            : SessionsError(error.message),
      );
    } finally {
      _isFetching = false;
    }
  }
}
