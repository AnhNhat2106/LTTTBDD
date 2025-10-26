import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/battle_service.dart';
import 'battle_result_screen.dart';

class BattleQuizScreen extends StatefulWidget {
  final String roomId;
  final String topicKey;
  final List<Map<String, dynamic>> questionList;

  const BattleQuizScreen({
    super.key,
    required this.roomId,
    required this.topicKey,
    required this.questionList,
  });

  @override
  State<BattleQuizScreen> createState() => _BattleQuizScreenState();
}

class _BattleQuizScreenState extends State<BattleQuizScreen> {
  int currentIndex = 0;
  int score = 0;
  bool submitted = false;

  void _answer(int idx) {
    final q = widget.questionList[currentIndex];
    if (idx == q['answer']) score++;
    if (currentIndex < widget.questionList.length - 1) {
      setState(() => currentIndex++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (submitted) return;
    submitted = true;
    await BattleService.instance.submitMyScore(
      roomId: widget.roomId,
      score: score,
      total: widget.questionList.length,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _WaitingResultScreen(
          roomId: widget.roomId,
          myScore: score,
          myTotal: widget.questionList.length,
          topic: widget.topicKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questionList[currentIndex];
    return Scaffold(
      appBar: AppBar(title: Text('Thi đấu - ${widget.topicKey}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Câu ${currentIndex + 1}/${widget.questionList.length}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(q['question'], style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ...List.generate(q['options'].length, (i) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  onPressed: () => _answer(i),
                  child: Text(q['options'][i]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _WaitingResultScreen extends StatelessWidget {
  final String roomId;
  final int myScore;
  final int myTotal;
  final String topic;

  const _WaitingResultScreen({
    required this.roomId,
    required this.myScore,
    required this.myTotal,
    required this.topic,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder(
      stream: BattleService.instance.watchRoom(roomId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = (snap.data! as dynamic).data();
        if (data == null) {
          return const Scaffold(body: Center(child: Text('Phòng không tồn tại')));
        }

        final status = (data['status'] as String?) ?? 'waiting';
        if (status != 'finished') {
          return const Scaffold(
            body: Center(child: Text('⏳ Đang chờ đối thủ hoàn thành...')),
          );
        }

        // Chỉ player1 finalize để tránh xử lý trùng
        final p1 = (data['player1'] as Map?)?['uid'];
        if (data['finalized'] != true && currentUid == p1) {
          BattleService.instance.finalizeAndRank(roomId);
        }

        final p2 = (data['player2'] as Map?)?['uid'];
        final p1Email = (data['player1'] as Map?)?['email'] ?? 'Người chơi 1';
        final p2Email = (data['player2'] as Map?)?['email'] ?? 'Người chơi 2';

        final scores = Map<String, dynamic>.from(data['scores'] ?? {});
        final s1 = p1 != null ? (scores[p1]?['score'] ?? 0) : 0;
        final t1 = p1 != null ? (scores[p1]?['total'] ?? 0) : 0;
        final s2 = p2 != null ? (scores[p2]?['score'] ?? 0) : 0;
        final t2 = p2 != null ? (scores[p2]?['total'] ?? 0) : 0;

        // ✅ Tự quyết định thắng/thua ngay từ điểm số để 2 máy đồng nhất
        String? winnerFromScores;
        if (s1 > s2) winnerFromScores = p1;
        if (s2 > s1) winnerFromScores = p2; // nếu bằng nhau => null (hòa)

        final bool? isMeWinner = (winnerFromScores == null)
            ? null
            : (winnerFromScores == currentUid);

        // Map dữ liệu theo phía người chơi hiện tại
        final myIsP1 = currentUid == p1;
        final myEmail = myIsP1 ? p1Email : p2Email;
        final oppEmail = myIsP1 ? p2Email : p1Email;
        final myScoreFinal = myIsP1 ? s1 : s2;
        final oppScoreFinal = myIsP1 ? s2 : s1;
        final oppTotalFinal = myIsP1 ? t2 : t1;

        // Điều hướng sang màn kết quả riêng cho PvP
        Future.microtask(() {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BattleResultScreen(
                topic: topic,
                myEmail: myEmail,
                oppEmail: oppEmail,
                myScore: myScoreFinal,
                oppScore: oppScoreFinal,
                myTotal: myTotal,
                oppTotal: oppTotalFinal,
                isMeWinner: isMeWinner,
              ),
            ),
          );
        });

        return const Scaffold(
          body: Center(child: Text('🎯 Đang tổng hợp kết quả...')),
        );
      },
    );
  }
}
