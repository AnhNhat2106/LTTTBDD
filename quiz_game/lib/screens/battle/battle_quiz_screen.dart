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
  const _WaitingResultScreen({super.key, required this.roomId});

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

        final status = data['status'] as String? ?? 'waiting';
        if (status != 'finished') {
          return const Scaffold(
            body: Center(child: Text('⏳ Đang chờ đối thủ hoàn thành...')),
          );
        }

        // ✅ Chỉ player1 finalize để tránh trùng
        if (data['finalized'] != true) {
          final p1 = data['player1'];
          if (currentUid == p1) {
            BattleService.instance.finalizeAndRank(roomId);
          }
        }

        // ✅ Khi cả hai hoàn tất, chuyển sang màn kết quả PvP
        Future.microtask(() {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BattleResultScreen(roomId: roomId)),
          );
        });

        return const Scaffold(
          body: Center(child: Text('🎯 Đang tổng hợp kết quả...')),
        );
      },
    );
  }
}
