import 'package:flutter/material.dart';
import '../../services/battle_service.dart';

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
        builder: (_) => _WaitingResultScreen(roomId: widget.roomId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questionList[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text('PvP - ${widget.topicKey}')),
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
                  onPressed: _answer == null ? null : () => _answer(i),
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
  const _WaitingResultScreen({required this.roomId, super.key});

  @override
  Widget build(BuildContext context) {
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
            body: Center(child: Text('Chờ đối thủ hoàn thành...')),
          );
        }

        // phòng đã finished -> finalize + show result
        BattleService.instance.finalizeAndRank(roomId); // fire-and-forget
        final scores = Map<String, dynamic>.from(data['scores'] ?? {});
        final p1 = (data['player1'] as Map?)?['uid'];
        final p2 = (data['player2'] as Map?)?['uid'];

        final s1 = p1 != null ? (scores[p1]?['score'] ?? 0) : 0;
        final t1 = p1 != null ? (scores[p1]?['total'] ?? 0) : 0;
        final s2 = p2 != null ? (scores[p2]?['score'] ?? 0) : 0;
        final t2 = p2 != null ? (scores[p2]?['total'] ?? 0) : 0;

        String label = 'Hoà!';
        if (s1 > s2) label = 'Người chơi 1 thắng!';
        if (s2 > s1) label = 'Người chơi 2 thắng!';

        return Scaffold(
          appBar: AppBar(title: const Text('Kết quả PvP')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('P1: $s1 / $t1'),
                  Text('P2: $s2 / $t2'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    child: const Text('Về Trang chủ'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
