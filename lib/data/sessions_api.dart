import 'package:http/http.dart' as http;

/// Low-level REST client. Only knows how to fetch the raw response body;
/// parsing and error mapping happen in [SessionsRepository].
class SessionsApi {
  SessionsApi({
    http.Client? client,
    Uri? endpoint,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       endpoint = endpoint ?? defaultEndpoint;

  static final defaultEndpoint = Uri.parse(
    'https://raw.githubusercontent.com/YASHRAJSIH/TechExpo/master/mock/sessions.json',
  );

  final http.Client _client;
  final Uri endpoint;
  final Duration timeout;

  /// Throws `SocketException`, `TimeoutException` or `http.ClientException`
  /// on network problems.
  Future<http.Response> fetchSessions() {
    return _client
        .get(endpoint, headers: const {'Accept': 'application/json'})
        .timeout(timeout);
  }

  void dispose() => _client.close();
}
