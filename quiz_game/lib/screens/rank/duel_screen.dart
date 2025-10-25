import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../quiz/topics.dart';
import '../quiz/quiz_screen.dart';

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

  /// 🔹 Tìm hoặc tạo phòng thi đấu
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

    // 1️⃣ Tìm phòng đang "waiting" cùng chủ đề
    final waitingRooms = await _db
        .collection('duel_rooms')
        .where('topic', isEqualTo: selectedTopic)
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (waitingRooms.docs.isNotEmpty) {
      // 2️⃣ Ghép vào phòng có sẵn
      final room = waitingRooms.docs.first.reference;
      await room.update({
        'player2': user.uid,
        'player2Email': user.email,
        'status': 'playing',
      });

      setState(() {
        statusText = '🥳 Ghép đấu thành công! Đang vào phòng...';
      });

      _listenToRoom(room.id);
    } else {
      // 3️⃣ Không có phòng -> tạo mới
      final newRoom = await _db.collection('duel_rooms').add({
        'topic': selectedTopic,
        'player1': user.uid,
        'player1Email': user.email,
        'player2': null,
        'player2Email': null,
        'player1Score': 0,
        'player2Score': 0,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        statusText = '⏳ Chờ đối thủ tham gia...';
      });

      _listenToRoom(newRoom.id);
    }
  }

  /// 🔹 Lắng nghe thay đổi của phòng
  void _listenToRoom(String roomId) {
    _db.collection('duel_rooms').doc(roomId).snapshots().listen((snap) async {
      if (!snap.exists) return;
      final data = snap.data()!;
      final status = data['status'];

      // Khi status chuyển sang "playing" → bắt đầu quiz
      if (status == 'playing') {
        final topic = data['topic'];
        final questions = topics[topic] ?? [];

        // 🚀 Bắt đầu quiz
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(
              topicKey: topic,
              questionList: questions,
            ),
          ),
        ).then((score) async {
          // 🔹 Nhận điểm trả về từ QuizScreen
          if (score == null) return;

          final field = data['player1'] == user.uid
              ? 'player1Score'
              : 'player2Score';

          await _db.collection('duel_rooms').doc(roomId).update({
            field: score,
          });

          // 🔹 Kiểm tra nếu cả 2 người đã có điểm → tính kết quả
          final updated = await _db.collection('duel_rooms').doc(roomId).get();
          final res = updated.data()!;
          final s1 = res['player1Score'] ?? 0;
          final s2 = res['player2Score'] ?? 0;

          if (s1 > 0 && s2 > 0) {
            await _finishMatch(res);
          }
        });
      }
    });
  }

  /// 🔹 Cập nhật kết quả thắng/thua & điểm rank
  Future<void> _finishMatch(Map<String, dynamic> room) async {
    final userRef = _db.collection('users').doc(user.uid);
    final data = await userRef.get();
    final current = data.data() ?? {};

    int rankPoints = (current['rankPoints'] ?? 0) as int;
    int wins = (current['wins'] ?? 0) as int;
    int losses = (current['losses'] ?? 0) as int;

    final s1 = room['player1Score'] ?? 0;
    final s2 = room['player2Score'] ?? 0;
    final isPlayer1 = room['player1'] == user.uid;

    bool isWin = (isPlayer1 && s1 > s2) || (!isPlayer1 && s2 > s1);

    // ✅ Nếu hòa thì không cộng/trừ
    if (s1 == s2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🤝 Hai bạn hòa nhau! Không thay đổi điểm rank.')),
      );
      return;
    }

    if (isWin) {
      rankPoints += 10;
      wins += 1;
    } else {
      rankPoints = (rankPoints - 5).clamp(0, 99999); // không âm điểm
      losses += 1;
    }

    await userRef.update({
      'rankPoints': rankPoints,
      'wins': wins,
      'losses': losses,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isWin
                ? '🏆 Bạn đã thắng +10 điểm rank!'
                : '😢 Bạn thua -5 điểm rank!',
          ),
        ),
      );
    }

    // 🔹 Cập nhật trạng thái phòng đã hoàn tất
    await _db.collection('duel_rooms').doc(room['id']).update({
      'status': 'finished',
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
                  .map(
                    (key) => DropdownMenuItem(
                  value: key,
                  child: Text(key),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => selectedTopic = v),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.sports_kabaddi),
              label: const Text('Tìm đối thủ'),
              onPressed: isSearching ? null : _findOpponent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  if (isSearching) const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    statusText,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
