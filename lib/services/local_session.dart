import 'package:flutter/foundation.dart';

/// Local, Firebase-free admin session — used for a dev/demo login that
/// bypasses auth and Firestore sync. When [active] is true:
///   - AuthGate treats the user as signed in
///   - SyncService skips all cloud reads/writes (everything is in-memory)
///   - Data lives only as long as the tab is open
class LocalAdminSession extends ChangeNotifier {
  static final instance = LocalAdminSession._();
  LocalAdminSession._();

  bool _active = false;
  bool get active => _active;

  static const String username = 'admin';
  static const String password = '2244';

  /// Returns true if [email] & [pass] match the admin credentials.
  static bool matches(String email, String pass) =>
      email.trim().toLowerCase() == username && pass == password;

  void start() {
    if (_active) return;
    _active = true;
    notifyListeners();
  }

  void end() {
    if (!_active) return;
    _active = false;
    notifyListeners();
  }
}
