import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

/// Holds the live Firebase [User] auth state and notifies the tree on
/// sign-in/out. Mirrors the SettingsController/SettingsScope pattern so any
/// screen can react to auth changes. Tolerates a null [FirebaseAuth] (e.g. if
/// Firebase failed to initialize) so the app stays usable offline.
class AuthController extends ChangeNotifier {
  AuthController(FirebaseAuth? auth) : _auth = auth {
    final auth = _auth;
    if (auth != null) {
      _user = auth.currentUser;
      _sub = auth.authStateChanges().listen((user) {
        _user = user;
        notifyListeners();
      });
    }
  }

  final FirebaseAuth? _auth;
  StreamSubscription<User?>? _sub;
  User? _user;

  User? get user => _user;
  bool get isSignedIn => _user != null;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Exposes the [AuthController] to the whole tree and rebuilds dependents when
/// auth state changes.
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope?.notifier != null, 'No AuthScope found in context');
    return scope!.notifier!;
  }
}
