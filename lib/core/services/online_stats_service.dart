import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/online_stats.dart';

/// Reads any player's online stats from `users/{uid}.online`. Used both for the
/// player's own profile and, later (REV-45), to show an opponent's basic stats.
/// These fields are written only by Cloud Functions, so this service is
/// read-only. Lazy Firestore access keeps Firebase-free widget tests working.
class OnlineStatsService {
  OnlineStatsService._();
  static final OnlineStatsService instance = OnlineStatsService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Map<String, dynamic>? _online(DocumentSnapshot<Map<String, dynamic>> snap) =>
      snap.data()?['online'] as Map<String, dynamic>?;

  Future<OnlineStats> fetch(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return OnlineStats.fromMap(_online(snap));
  }

  Stream<OnlineStats> watch(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => OnlineStats.fromMap(_online(snap)));
}
