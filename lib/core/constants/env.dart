/// Backend base URL. Override at build/run time, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1/
/// (10.0.2.2 is the Android emulator's alias for the host's localhost.)
/// Falls back to the hosted Render backend.
abstract class Env {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  // Optional dev tunnel: paste a fresh ngrok URL as '<url>/api/v1/' to point the
  // app at your local backend (e.g. from `ngrok http 5000`). Or pass
  // --dart-define=API_BASE_URL=... at run time (that wins over this). Leave ''
  // to use the hosted backend. Keep this '' in commits.
  static const String _devTunnel = '';

  static const String _hosted =
      'https://expense-tracker-be-3rvm.onrender.com/api/v1/';

  static String get apiBaseUrl {
    final raw = _override.isNotEmpty
        ? _override
        : (_devTunnel.isNotEmpty ? _devTunnel : _hosted);
    return raw.endsWith('/') ? raw : '$raw/';
  }
}
