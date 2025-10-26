import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../quiz/topics.dart';
import '../quiz/quiz_screen.dart';
import '../quiz/result_screen.dart';

class DuelScreen extends StatefulWidget {
  const DuelScreen({super.key});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  String? selectedTopic;
  bool isSearching = false;
  String statusText = 'Chọn chủ đề để thi đấu';

  final user = FirebaseAuth.instance.currentUser!;
  final _db = FirebaseFirestore.instance;

  String? _roomId;
  bool _iCreated = false;
  StreamSubscription<DocumentSnapshot>? _roomSub;

  String? _opponentId;
  String? _opponentName;
  bool hasStarted = false;

  @override
  void dispose() {
    _roomSub?.cancel();
    super.dispose();
  }

  Future<void> _findOpponent() async {
    if (selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn chủ đề trước khi thi đấu!')),
      );
      return;
    }

    setState(() {
      isSearching = true;
      statusText = '🔍 Đang tìm đối thủ...';
    });

    final waiting = await _db
        .collection('duel_rooms')
        .where('topic', isEqualTo: selectedTopic)
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (waiting.docs.isNotEmpty) {
      // Tham gia phòng có sẵn
      final room = waiting.docs.first;
      _roomId = room.id;
      _iCreated = false;

      await room.reference.update({
        'player2': user.uid,
        'player2Email': user.email,
        'status': 'playing',
      });

      _listenToRoom(room.id);
      setState(() => statusText = '🥳 Đã ghép đối thủ, chờ xác nhận...');
    } else {
      // Tạo phòng mới
      final newRoom = await _db.collection('duel_rooms').add({
        'topic': selectedTopic,
        'player1': user.uid,
        'player1Email': user.email,
        'player2': null,
        'player2Email': null,
        'player1Score': null,
        'player2Score': null,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _roomId = newRoom.id;
      _iCreated = true;
      _listenToRoom(newRoom.id);
      setState(() => statusText = '⏳ Chờ đối thủ tham gia...');
    }
  }

  Future<void> _cancelSearch() async {
    if (!isSearching) return;
    if (_iCreated && _roomId != null) {
      final roomSnap = await _db.collection('duel_rooms').doc(_roomId!).get();
      if (roomSnap.exists && (roomSnap.data()?['status'] == 'waiting')) {
        await _db.collection('duel_rooms').doc(_roomId!).delete();
      }
    }
    _roomSub?.cancel();
    setState(() {
      _roomId = null;
      isSearching = false;
      statusText = 'Đã hủy tìm đối thủ';
      hasStarted = false;
    });
  }

  void _listenToRoom(String roomId) {
    _roomSub?.cancel();
    _roomSub =
        _db.collection('duel_rooms').doc(roomId).snapshots().listen((snap) async {
          if (!snap.exists) return;
          final data = snap.data()!;
          final status = data['status'] as String;

          final p1 = data['player1'];
          final p2 = data['player2'];
          final myId = user.uid;
          _opponentId = myId == p1 ? p2 : p1;

          if (_opponentId != null) {
            final u = await _db.collection('users').doc(_opponentId).get();
            _opponentName =
                (u.data()?['displayName'] ?? u.data()?['email'] ?? 'Đối thủ')
                    .toString();
          }

          if (status == 'playing' && !hasStarted) {
            hasStarted = true;

            if (mounted) {
              final ok = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  title: const Text('Đã tìm thấy đối thủ'),
                  content: Text(
                    'Đối thủ: ${_opponentName ?? '???'}\nBấm "Bắt đầu" để vào trận.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Thoát'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Bắt đầu'),
                    ),
                  ],
                ),
              ) ??
                  false;

              if (!ok) {
                hasStarted = false;
                _cancelSearch();
                return;
              }
            }

            final topic = data['topic'];
            final questions = topics[topic] ?? [];
            if (!mounted) return;

            final myScore = await Navigator.push<int>(
              context,
              MaterialPageRoute(
                builder: (_) => QuizScreen(
                  topicKey: topic,
                  questionList: questions,
                  isDuel: true,
                ),
              ),
            );

            final field =
            (data['player1'] == user.uid) ? 'player1Score' : 'player2Score';
            await _db.collection('duel_rooms').doc(roomId).update({
              field: myScore ?? 0,
            });

            await _tryFinishMatch(roomId);
          }

          if (status == 'finished' && mounted) {
            _showResult(data);
          }
        });
  }

  Future<void> _tryFinishMatch(String roomId) async {
    final ref = _db.collection('duel_rooms').doc(roomId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final room = snap.data()!;
    if (room['status'] == 'finished') return;

    final s1 = room['player1Score'];
    final s2 = room['player2Score'];
    if (s1 == null || s2 == null) return; // 1 người chưa xong → chờ tiếp

    String? winner;
    if (s1 > s2) winner = room['player1'];
    if (s2 > s1) winner = room['player2'];

    final uid1 = room['player1'] as String;
    final uid2 = room['player2'] as String?;

    try {
      await _db.runTransaction((trx) async {
        final u1ref = _db.collection('users').doc(uid1);
        final u2ref =
        (uid2 != null) ? _db.collection('users').doc(uid2) : null;

        Map<String, dynamic> inc1 = {};
        Map<String, dynamic> inc2 = {};

        if (winner == null) {
          inc1 = {'rankPoints': FieldValue.increment(2)};
          inc2 = {'rankPoints': FieldValue.increment(2)};
        } else if (winner == uid1) {
          inc1 = {
            'rankPoints': FieldValue.increment(10),
            'wins': FieldValue.increment(1),
          };
          inc2 = {
            'rankPoints': FieldValue.increment(-5),
            'losses': FieldValue.increment(1),
          };
        } else {
          inc1 = {
            'rankPoints': FieldValue.increment(-5),
            'losses': FieldValue.increment(1),
          };
          inc2 = {
            'rankPoints': FieldValue.increment(10),
            'wins': FieldValue.increment(1),
          };
        }

        trx.set(u1ref, inc1, SetOptions(merge: true));
        if (u2ref != null) trx.set(u2ref, inc2, SetOptions(merge: true));

        trx.update(ref, {
          'status': 'finished',
          'winner': winner,
          'finishedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      await ref.update({
        'status': 'finished',
        'winner': winner,
        'finishedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Finalize duel fallback: $e');
    }

    if (!mounted) return;
    _showResult(room);
  }

  void _showResult(Map<String, dynamic> room) async {
    if (!mounted) return;

    final s1 = room['player1Score'] ?? 0;
    final s2 = room['player2Score'] ?? 0;
    final topic = (room['topic'] ?? 'Không rõ') as String;
    final total = (topics[topic]?.length ?? 10);

    final winner = room['winner'];
    final isMeWinner = (winner == null)
        ? null
        : (winner == FirebaseAuth.instance.currentUser?.uid);

    final msg = (isMeWinner == null)
        ? '🤝 Trận đấu kết thúc: HOÀ'
        : (isMeWinner
        ? '🏆 Bạn THẮNG! +10 điểm rank'
        : '😢 Bạn THUA -5 điểm rank');

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    await Future.delayed(const Duration(milliseconds: 800));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          topicKey: topic,
          score: (room['player1'] == user.uid) ? s1 : s2,
          total: total,
        ),
      ),
    );

    setState(() {
      isSearching = false;
      hasStarted = false;
      statusText = 'Trận đấu đã kết thúc';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thi đấu xếp hạng ⚔️'),
        backgroundColor: color.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Chọn chủ đề thi đấu',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              value: selectedTopic,
              items: topics.keys
                  .map((key) =>
                  DropdownMenuItem(value: key, child: Text(key)))
                  .toList(),
              onChanged: (v) => setState(() => selectedTopic = v),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sports_kabaddi),
                    label: Text(isSearching
                        ? 'Đang tìm đối thủ…'
                        : 'Tìm đối thủ'),
                    onPressed: isSearching ? null : _findOpponent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Hủy'),
                    onPressed: isSearching ? _cancelSearch : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  if (isSearching) const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(
                    statusText,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  if (_opponentName != null && isSearching) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Đối thủ: ${_opponentName!}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
