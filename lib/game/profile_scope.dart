import 'package:flutter/widgets.dart';

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

/// Skeleton profile holder. Today it derives the profile from the auth user;
/// REV-38 will load and merge the Firestore profile document here.
class ProfileController extends ChangeNotifier {
  ProfileController(this._auth) {
    _auth.addListener(_syncFromAuth);
    _syncFromAuth();
  }

  final AuthController _auth;
  Profile? _profile;

  Profile? get profile => _profile;

  void _syncFromAuth() {
    final user = _auth.user;
    final next = user == null
        ? null
        : Profile(
            uid: user.uid,
            displayName: user.displayName,
            photoUrl: user.photoURL,
          );
    if (next?.uid == _profile?.uid &&
        next?.displayName == _profile?.displayName &&
        next?.photoUrl == _profile?.photoUrl) {
      return;
    }
    _profile = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_syncFromAuth);
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
