import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BattleService {
  BattleService._();
  static final BattleService instance = BattleService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// 🔹 Tạo phòng chờ theo chủ đề
  Future<String> createRoom({required String topic}) async {
    final u = _auth.currentUser!;
    final doc = await _db.collection('rooms').add({
      'topic': topic,
      'status': 'waiting', // waiting | playing | finished
      'createdAt': FieldValue.serverTimestamp(),
      'player1': {
        'uid': u.uid,
        'email': u.email,
        'displayName': u.displayName ?? '',
      },
      'player2': null,
      'scores': {}, // {uid: {'score': x, 'total': y}}
      'startedAt': null,
      'finishedAt': null,
      'finalized': false,
    });
    return doc.id;
  }

  /// 🔹 Ghép phòng tự động
  Future<String> autoMatchOrCreate({required String topic}) async {
    final waiting = await _db
        .collection('rooms')
        .where('topic', isEqualTo: topic)
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt')
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

  /// 🔹 Người thứ hai vào phòng
  Future<void> joinRoom(String roomId) async {
    final u = _auth.currentUser!;
    final ref = _db.collection('rooms').doc(roomId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Phòng không tồn tại');
      final data = snap.data()!;
      if (data['status'] != 'waiting') throw Exception('Phòng đã bắt đầu');
      if (data['player2'] != null) throw Exception('Phòng đã đủ người');

      tx.update(ref, {
        'player2': {
          'uid': u.uid,
          'email': u.email,
          'displayName': u.displayName ?? '',
        },
        'status': 'playing',
        'startedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 🔹 Lắng nghe phòng theo thời gian thực
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String roomId) {
    return _db.collection('rooms').doc(roomId).snapshots();
  }

  /// 🔹 Nộp điểm của mình
  Future<void> submitMyScore({
    required String roomId,
    required int score,
    required int total,
  }) async {
    final u = _auth.currentUser!;
    final ref = _db.collection('rooms').doc(roomId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;

      // Lưu điểm người chơi hiện tại
      final scores = Map<String, dynamic>.from(data['scores'] ?? {});
      scores[u.uid] = {'score': score, 'total': total};
      tx.update(ref, {'scores': scores});

      // Nếu cả 2 người đều đã nộp điểm → kết thúc trận
      final p1 = (data['player1'] as Map?)?['uid'];
      final p2 = (data['player2'] as Map?)?['uid'];
      final haveP1 = p1 != null && scores[p1] != null;
      final haveP2 = p2 != null && scores[p2] != null;

      if (haveP1 && haveP2) {
        tx.update(ref, {
          'status': 'finished',
          'finishedAt': FieldValue.serverTimestamp(),
        });
      }
    }).catchError((e) {
      print('❌ Lỗi submitMyScore: $e');
    });
  }

  /// 🔹 Tổng kết & cập nhật Rank + lưu lịch sử trận
  Future<void> finalizeAndRank(String roomId) async {
    final ref = _db.collection('rooms').doc(roomId);
    final room = await ref.get();
    if (!room.exists) return;

    final data = room.data()!;
    if (data['status'] != 'finished') return;
    if (data['finalized'] == true) return; // tránh xử lý 2 lần

    final topic = data['topic'];
    final p1 = (data['player1'] as Map?)?['uid'];
    final p2 = (data['player2'] as Map?)?['uid'];
    final scores = Map<String, dynamic>.from(data['scores'] ?? {});
    if (p1 == null || p2 == null) return;
    if (scores[p1] == null || scores[p2] == null) return;

    final s1 = (scores[p1]['score'] ?? 0) as int;
    final t1 = (scores[p1]['total'] ?? 0) as int;
    final s2 = (scores[p2]['score'] ?? 0) as int;
    final t2 = (scores[p2]['total'] ?? 0) as int;

    String? winner;
    String result = 'draw';
    if (s1 > s2) {
      winner = p1;
      result = 'p1_win';
    } else if (s2 > s1) {
      winner = p2;
      result = 'p2_win';
    }

    // ✅ Lưu lịch sử trận đấu (đây là phần giúp hiển thị trong DuelHistoryScreen)
    await _db.collection('battle_results').add({
      'roomId': roomId,
      'topic': topic,
      'player1Email': data['player1']?['email'],
      'player2Email': data['player2']?['email'],
      'player1Score': s1,
      'player2Score': s2,
      'winner': winner,
      'status': 'finished',
      'finishedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Đã lưu lịch sử trận $roomId vào battle_results');

    // Cập nhật Rank
    final p1Ref = _db.collection('users').doc(p1);
    final p2Ref = _db.collection('users').doc(p2);

    try {
      await _db.runTransaction((trx) async {
        if (winner == null) {
          // Hòa
          trx.set(p1Ref, {
            'rankPoints': FieldValue.increment(2),
          }, SetOptions(merge: true));
          trx.set(p2Ref, {
            'rankPoints': FieldValue.increment(2),
          }, SetOptions(merge: true));
        } else if (winner == p1) {
          // P1 thắng
          trx.set(p1Ref, {
            'rankPoints': FieldValue.increment(10),
            'wins': FieldValue.increment(1),
          }, SetOptions(merge: true));
          trx.set(p2Ref, {
            'rankPoints': FieldValue.increment(-5),
            'losses': FieldValue.increment(1),
          }, SetOptions(merge: true));
        } else {
          // P2 thắng
          trx.set(p2Ref, {
            'rankPoints': FieldValue.increment(10),
            'wins': FieldValue.increment(1),
          }, SetOptions(merge: true));
          trx.set(p1Ref, {
            'rankPoints': FieldValue.increment(-5),
            'losses': FieldValue.increment(1),
          }, SetOptions(merge: true));
        }

        trx.update(ref, {'finalized': true});
      });
    } catch (e) {
      print('⚠️ finalizeAndRank lỗi: $e');
      await ref.update({'finalized': true});
    }
  }
}
