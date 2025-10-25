import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BattleService {
  BattleService._();
  static final BattleService instance = BattleService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Tạo phòng chờ theo topic. Trả về roomId.
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
      'scores': {}, // {uid: int}
      'startedAt': null,
      'finishedAt': null,
    });
    return doc.id;
  }

  /// Tìm phòng còn đang waiting cùng topic để join. Nếu không có -> tạo mới.
  Future<String> autoMatchOrCreate({required String topic}) async {
    final waiting = await _db.collection('rooms')
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

  /// Vào phòng đang waiting (làm player2) và đổi status thành playing.
  Future<void> joinRoom(String roomId) async {
    final u = _auth.currentUser!;
    final ref = _db.collection('rooms').doc(roomId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception('Phòng không tồn tại');
      }
      final data = snap.data()!;
      if (data['status'] != 'waiting') {
        throw Exception('Phòng đã bắt đầu/đóng');
      }
      if (data['player2'] != null) {
        throw Exception('Phòng đã đủ người');
      }
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

  /// Lắng nghe realtime một phòng
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String roomId) {
    return _db.collection('rooms').doc(roomId).snapshots();
  }

  /// Nộp điểm của mình sau khi làm xong
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

      final scores = Map<String, dynamic>.from(data['scores'] ?? {});
      scores[u.uid] = {'score': score, 'total': total};

      tx.update(ref, {'scores': scores});

      // Nếu cả 2 người đã nộp điểm -> kết thúc phòng
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
    });
  }

  /// Khi phòng finished, ghi kết quả vào battle_results + cập nhật rank users
  Future<void> finalizeAndRank(String roomId) async {
    final ref = _db.collection('rooms').doc(roomId);
    final room = await ref.get();
    if (!room.exists) return;

    final data = room.data()!;
    if (data['status'] != 'finished') return;

    final topic = data['topic'];
    final p1 = (data['player1'] as Map?)?['uid'];
    final p2 = (data['player2'] as Map?)?['uid'];
    final scores = Map<String, dynamic>.from(data['scores'] ?? {});
    if (p1 == null || p2 == null) return;
    if (scores[p1] == null || scores[p2] == null) return;

    final s1 = scores[p1]['score'] as int;
    final t1 = scores[p1]['total'] as int;
    final s2 = scores[p2]['score'] as int;
    final t2 = scores[p2]['total'] as int;

    String? winner;
    String result = 'draw';
    if (s1 > s2) {
      winner = p1;
      result = 'p1_win';
    } else if (s2 > s1) {
      winner = p2;
      result = 'p2_win';
    }

    // lưu battle_results
    await _db.collection('battle_results').add({
      'roomId': roomId,
      'topic': topic,
      'p1': {'uid': p1, 'score': s1, 'total': t1},
      'p2': {'uid': p2, 'score': s2, 'total': t2},
      'winnerUid': winner,
      'result': result, // p1_win | p2_win | draw
      'createdAt': FieldValue.serverTimestamp(),
    });

    // cộng/trừ rank
    final p1Ref = _db.collection('users').doc(p1);
    final p2Ref = _db.collection('users').doc(p2);

    if (winner == null) {
      // hoà: +2 cả 2
      await p1Ref.update({
        'rankPoints': FieldValue.increment(2),
      });
      await p2Ref.update({
        'rankPoints': FieldValue.increment(2),
      });
    } else if (winner == p1) {
      await p1Ref.update({
        'rankPoints': FieldValue.increment(10),
        'wins': FieldValue.increment(1),
      });
      await p2Ref.update({
        'rankPoints': FieldValue.increment(-5),
        'losses': FieldValue.increment(1),
      });
    } else {
      await p2Ref.update({
        'rankPoints': FieldValue.increment(10),
        'wins': FieldValue.increment(1),
      });
      await p1Ref.update({
        'rankPoints': FieldValue.increment(-5),
        'losses': FieldValue.increment(1),
      });
    }
  }
}
