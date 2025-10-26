import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BattleService {
  BattleService._();
  static final BattleService instance = BattleService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('duel_rooms');

  /// 🏁 Tạo phòng chờ
  Future<String> createRoom({required String topic}) async {
    final u = _auth.currentUser!;
    final doc = await _rooms.add({
      'topic': topic,
      'status': 'waiting', // waiting | playing | finished
      'createdAt': FieldValue.serverTimestamp(),
      'player1': u.uid,
      'player1Email': u.email,
      'player1Score': null,
      'player2': null,
      'player2Email': null,
      'player2Score': null,
      'winner': null,
      'finishedAt': null,
      'finalized': false,
    });
    return doc.id;
  }

  /// 🔍 Ghép phòng tự động: ưu tiên phòng waiting
  Future<String> autoMatchOrCreate({required String topic}) async {
    final waiting = await _rooms
        .where('topic', isEqualTo: topic)
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (waiting.docs.isEmpty) {
      return createRoom(topic: topic);
    } else {
      final roomRef = waiting.docs.first.reference;
      await joinRoom(roomRef.id);
      return roomRef.id;
    }
  }

  /// 👥 Người thứ hai vào phòng
  Future<void> joinRoom(String roomId) async {
    final u = _auth.currentUser!;
    final ref = _rooms.doc(roomId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Phòng không tồn tại');
      final data = snap.data()!;
      if (data['status'] != 'waiting') throw Exception('Phòng đã bắt đầu');
      if (data['player2'] != null) throw Exception('Phòng đã đủ người');

      tx.update(ref, {
        'player2': u.uid,
        'player2Email': u.email,
        'status': 'playing',
        'startedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 👂 Lắng nghe phòng realtime
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String roomId) {
    return _rooms.doc(roomId).snapshots();
  }

  /// 📝 Nộp điểm của mình
  Future<void> submitMyScore({
    required String roomId,
    required int score,
    required int total,
  }) async {
    final u = _auth.currentUser!;
    final ref = _rooms.doc(roomId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;

      final isP1 = data['player1'] == u.uid;
      final field = isP1 ? 'player1Score' : 'player2Score';
      tx.update(ref, {field: score});

      final s1 = isP1 ? score : data['player1Score'];
      final s2 = isP1 ? data['player2Score'] : score;

      if (s1 != null && s2 != null) {
        tx.update(ref, {
          'status': 'finished',
          'finishedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// 🧮 Tổng kết & cập nhật Rank + winner (chạy 1 lần)
  Future<void> finalizeAndRank(String roomId) async {
    final ref = _rooms.doc(roomId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    if (data['status'] != 'finished') return;
    if (data['finalized'] == true) return;

    final p1 = data['player1'];
    final p2 = data['player2'];
    if (p1 == null || p2 == null) return;

    final s1 = (data['player1Score'] ?? 0) as int;
    final s2 = (data['player2Score'] ?? 0) as int;
    final topic = data['topic'] ?? 'Chưa rõ';
    final p1Email = data['player1Email'] ?? '';
    final p2Email = data['player2Email'] ?? '';

    String? winner;
    if (s1 > s2) winner = p1;
    if (s2 > s1) winner = p2;

    final p1Ref = _db.collection('users').doc(p1);
    final p2Ref = _db.collection('users').doc(p2);

    await _db.runTransaction((tx) async {
      // ✅ Cộng/trừ điểm rank
      if (winner == null) {
        tx.set(p1Ref, {'rankPoints': FieldValue.increment(2)}, SetOptions(merge: true));
        tx.set(p2Ref, {'rankPoints': FieldValue.increment(2)}, SetOptions(merge: true));
      } else if (winner == p1) {
        tx.set(p1Ref, {
          'rankPoints': FieldValue.increment(10),
          'wins': FieldValue.increment(1),
        }, SetOptions(merge: true));
        tx.set(p2Ref, {
          'rankPoints': FieldValue.increment(-5),
          'losses': FieldValue.increment(1),
        }, SetOptions(merge: true));
      } else {
        tx.set(p2Ref, {
          'rankPoints': FieldValue.increment(10),
          'wins': FieldValue.increment(1),
        }, SetOptions(merge: true));
        tx.set(p1Ref, {
          'rankPoints': FieldValue.increment(-5),
          'losses': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }

      // ✅ Cập nhật lại duel_rooms với winner + topic + email
      tx.update(ref, {
        'winner': winner,
        'finalized': true,
        'topic': topic,
        'player1Email': p1Email,
        'player2Email': p2Email,
        'finishedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
