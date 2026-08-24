import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_prefs.dart';

/// Push notifications: permission, the device token, and where it is kept
/// (REV-111).
///
/// **This lays the pipe and nothing else.** Nothing in the app sends a
/// notification yet — what gets sent, and when, is REV-113/114. What exists
/// here is the part those cannot be built without: a player who has agreed, and
/// a token the server can address.
///
/// **Where the token lives, and why it is not on the profile.** It goes in
/// `users/{uid}/devices/{token}`, a subcollection with its own rules, never as
/// a field on `users/{uid}`. That document's write whitelist — displayName,
/// photoUrl, updatedAt — is what stops a client from editing its own coins and
/// trophies, and it is not being widened for a convenience.
///
/// **One document per device**, keyed by the token itself: a player with a
/// phone and a tablet should be reachable on both, and a token that Firebase
/// rotates leaves the old document behind rather than overwriting a sibling.
///
/// **Guests never register.** A guest has no user document, and "a guest leaves
/// no trace on the server" (REV-53/57) is not being traded for a notification.
class NotificationService {
  NotificationService._()
      : _messagingOverride = null,
        _firestoreOverride = null,
        _prefs = const NotificationPrefs();
  static final NotificationService instance = NotificationService._();

  @visibleForTesting
  NotificationService.forTest({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    NotificationPrefs prefs = const NotificationPrefs(),
  })  : _messagingOverride = messaging,
        _firestoreOverride = firestore,
        _prefs = prefs;

  final FirebaseMessaging? _messagingOverride;
  final FirebaseFirestore? _firestoreOverride;
  final NotificationPrefs _prefs;

  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  StreamSubscription<String>? _refreshSub;

  /// The token this device last registered, so sign-out knows what to delete.
  String? _registeredToken;
  String? _registeredUid;

  /// Whether the player has already granted permission, without asking for it.
  ///
  /// `getNotificationSettings` reads the current state; it never prompts. That
  /// distinction is the whole reason this is separate from [requestPermission]:
  /// a launch must be able to find out where it stands without spending the one
  /// prompt the platform will show.
  Future<bool> isGranted() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('Notification settings unavailable: $e');
      return false;
    }
  }

  /// Shows the system permission prompt and records that it happened.
  ///
  /// The record is kept whatever the answer, because the prompt itself is
  /// spent: Android 13+ shows it once, and a refusal there cannot be revisited
  /// from inside the app.
  Future<bool> requestPermission() async {
    await _prefs.markAsked();
    try {
      final settings = await _messaging.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return false;
    }
  }

  /// Writes this device's token under [uid] and keeps it current.
  ///
  /// Safe to call on every launch, and on every rebuild that notices a profile:
  /// the same token writes the same document, `lastSeenAt` moving is the point
  /// — a token nobody has used for months is how a notification ends up on a
  /// phone that was traded in — and a repeat call for a uid already registered
  /// returns without touching the network.
  ///
  /// Failures are swallowed. Not being reachable by push is a missing extra,
  /// never a reason to interrupt someone who is trying to play.
  Future<void> registerDevice({
    required String uid,
    required bool isGuest,
    required String lang,
  }) async {
    if (_registeredUid == uid && _registeredToken != null) return;
    if (!shouldRegisterDevice(
      signedIn: true,
      isGuest: isGuest,
      granted: await isGranted(),
    )) {
      return;
    }

    try {
      final token = await _messaging.getToken();
      debugPrint('FCM token: ${token == null ? 'none' : 'obtained'}');
      if (token == null) {
        // Normal on iOS with no APNs key uploaded yet, and on a device with no
        // Play Services. Nothing is broken; there is just nowhere to send to.
        debugPrint('No FCM token on this device.');
        return;
      }
      await _writeToken(uid: uid, token: token, lang: lang);

      // Firebase rotates tokens on its own schedule (reinstall, restore,
      // clearing app data). Without this the server keeps addressing a token
      // that stopped existing, and the player quietly goes silent.
      await _refreshSub?.cancel();
      _refreshSub = _messaging.onTokenRefresh.listen((fresh) async {
        await _writeToken(uid: uid, token: fresh, lang: lang);
      });
    } catch (e) {
      debugPrint('Device registration failed: $e');
    }
  }

  Future<void> _writeToken({
    required String uid,
    required String token,
    required String lang,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(token);

    // `createdAt` is sent only on the first write, and the rules refuse to let
    // an update touch it: "first registered" has to survive every later
    // launch, and a merge that always sends it would reset it to today.
    final existing = await ref.get();
    await ref.set({
      'platform': _platform,
      'lang': lang,
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _registeredToken = token;
    _registeredUid = uid;
    // One line, on purpose: without it a device that never registered and one
    // that registered fine look identical from a log, and the difference is
    // the whole feature.
    debugPrint('Push device registered for $uid');
  }

  /// Removes this device from the signed-out account.
  ///
  /// Not housekeeping — correctness. Phones get handed over and shared; if the
  /// token stayed under the previous account, the next person to pick it up
  /// would receive that account's notifications.
  ///
  /// Called *before* the sign-out, while the rules still recognise the owner.
  Future<void> unregisterDevice() async {
    await _refreshSub?.cancel();
    _refreshSub = null;

    final token = _registeredToken;
    final uid = _registeredUid;
    _registeredToken = null;
    _registeredUid = null;
    if (token == null || uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(token)
          .delete();
    } catch (e) {
      debugPrint('Device unregistration failed: $e');
    }
  }

  /// Routes a tapped notification to the screen it is about (REV-114).
  ///
  /// Two entry points, and both are needed: [getInitialMessage] is the message
  /// that *launched* a closed app, [onMessageOpenedApp] the one tapped while it
  /// was in the background. Handling only the second means a notification that
  /// starts the app cold drops the player on the menu with no idea why.
  ///
  /// Installed after the first frame so the navigator exists.
  Future<void> installTapHandling(void Function(String gameId) openMatch) async {
    void handle(RemoteMessage? message) {
      if (message == null) return;
      final data = message.data;
      if (data['type'] != 'match_found') return;
      final gameId = data['gameId'];
      if (gameId is! String || gameId.isEmpty) return;
      openMatch(gameId);
    }

    try {
      handle(await _messaging.getInitialMessage());
      await _openedSub?.cancel();
      // A static stream on the plugin, not an instance member.
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(handle);
    } catch (e) {
      debugPrint('Notification tap handling unavailable: $e');
    }
  }

  StreamSubscription<RemoteMessage>? _openedSub;

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'other';
  }
}
