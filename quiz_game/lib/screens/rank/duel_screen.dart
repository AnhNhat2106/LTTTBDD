import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../quiz/topics.dart';
import '../quiz/quiz_screen.dart';
import '../../services/quiz_service.dart';

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

    // 🔹 Tạo phòng đấu tạm thời
    final roomRef = _db.collection('duel_rooms').doc();
    await roomRef.set({
      'topic': selectedTopic,
      'player1': user.uid,
      'player1Email': user.email,
      'player2': null,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'waiting',
    });

    // 🔹 Giả lập chờ 3 giây (chưa có người thì đấu với BOT)
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      isSearching = false;
      statusText = '🥊 Ghép đấu thành công! (Tạm thời với BOT)';
    });

    _startMatch(isBot: true);
  }

  void _startMatch({bool isBot = false}) {
    final topicQuestions = topics[selectedTopic];
    if (topicQuestions == null || topicQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chủ đề này chưa có câu hỏi!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          topicKey: selectedTopic!,
          questionList: topicQuestions,
        ),
      ),
    ).then((_) {
      _updateRank(isWin: true); // ✅ Tạm coi người chơi thắng BOT
    });
  }

  Future<void> _updateRank({required bool isWin}) async {
    final userRef = _db.collection('users').doc(user.uid);
    final snap = await userRef.get();
    final data = snap.data() ?? {};

    int currentPoints = (data['rankPoints'] ?? 0) as int;
    int wins = (data['wins'] ?? 0) as int;
    int losses = (data['losses'] ?? 0) as int;

    if (isWin) {
      currentPoints += 10;
      wins += 1;
    } else {
      currentPoints -= 5;
      losses += 1;
    }

    await userRef.update({
      'rankPoints': currentPoints,
      'wins': wins,
      'losses': losses,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isWin ? '🎉 Bạn thắng! +10 điểm rank' : '😢 Bạn thua -5 điểm rank',
        ),
      ),
    );
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
        elevation: 2,
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
              icon: Icon(Icons.sports_kabaddi),
              label: Text('Tìm đối thủ'),
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
