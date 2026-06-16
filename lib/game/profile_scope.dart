import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../services/profile_service.dart';
import 'auth_scope.dart';

/// The player's profile. For now it mirrors the signed-in Google account's
/// name and photo; REV-38 will back it with the Firestore `users/{uid}`
/// document (level, xp, online stats), which only Cloud Functions may write.
@immutable
class Profile {
  const Profile({
    required this.uid,
    this.displayName,
    this.photoUrl,
    this.level = 1,
    this.xp = 0,
  });

  final String uid;
  final String? displayName;
  final String? photoUrl;
  final int level;
  final int xp;
}

/// Holds the player's [Profile]. On sign-in it shows the account's name/photo
/// immediately, persists the profile to Firestore (`users/{uid}`) and then
/// streams that document so server-written fields (level, xp) stay live.
class ProfileController extends ChangeNotifier {
  ProfileController(this._auth, {ProfileService? service})
      : _service = service ?? ProfileService.instance {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final AuthController _auth;
  final ProfileService _service;

  Profile? _profile;
  String? _boundUid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;

  Profile? get profile => _profile;

  void _onAuthChanged() {
    final user = _auth.user;

    if (user == null) {
      _boundUid = null;
      _docSub?.cancel();
      _docSub = null;
      if (_profile != null) {
        _profile = null;
        notifyListeners();
      }
      return;
    }

    if (user.uid == _boundUid) return; // already bound to this account
    _boundUid = user.uid;

    // Show the account identity right away so the UI never waits on Firestore.
    _profile = Profile(
      uid: user.uid,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
    notifyListeners();

    // Persist the profile and then keep it in sync with Firestore.
    unawaited(_service.ensureProfile(user).catchError(
          (Object e) => debugPrint('ensureProfile failed: $e'),
        ));

    _docSub?.cancel();
    _docSub = _service.watch(user.uid).listen(
      (snap) {
        final data = snap.data();
        if (data == null) return;
        _profile = Profile(
          uid: user.uid,
          displayName: data['displayName'] as String? ?? user.displayName,
          photoUrl: data['photoUrl'] as String? ?? user.photoURL,
          level: (data['level'] as num?)?.toInt() ?? 1,
          xp: (data['xp'] as num?)?.toInt() ?? 0,
        );
        notifyListeners();
      },
      onError: (Object e) => debugPrint('profile watch error: $e'),
    );
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _docSub?.cancel();
    super.dispose();
  }
}

/// Exposes the [ProfileController] to the tree and rebuilds dependents when the
/// profile changes.
class ProfileScope extends InheritedNotifier<ProfileController> {
  const ProfileScope({
    super.key,
    required ProfileController controller,
    required super.child,
  }) : super(notifier: controller);

  static ProfileController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProfileScope>();
    assert(scope?.notifier != null, 'No ProfileScope found in context');
    return scope!.notifier!;
  }
}
