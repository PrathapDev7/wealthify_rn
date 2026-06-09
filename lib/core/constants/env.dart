/// Backend base URL. Override at build/run time, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1/
/// (10.0.2.2 is the Android emulator's alias for the host's localhost.)
/// Falls back to the hosted Render backend.
abstract class Env {
  static const String _override = String.fromEnvironment('API_BASE_URL');
  static const String _hosted =
      'https://expense-tracker-be-3rvm.onrender.com/api/v1/';

  static String get apiBaseUrl {
    final raw = _override.isNotEmpty ? _override : _hosted;
    return raw.endsWith('/') ? raw : '$raw/';
  }
}
