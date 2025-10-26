import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/battle_service.dart';

class BattleResultScreen extends StatelessWidget {
  final String roomId;
  const BattleResultScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    final color = Theme.of(context).colorScheme;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: BattleService.instance.watchRoom(roomId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Kết quả thi đấu')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data!.data();
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Kết quả thi đấu')),
            body: const Center(child: Text('Phòng không tồn tại!')),
          );
        }

        final status = (data['status'] ?? 'waiting') as String;
        if (status != 'finished') {
          return Scaffold(
            appBar: AppBar(title: const Text('Kết quả thi đấu')),
            body: const Center(child: Text('⏳ Chờ đối thủ hoàn thành...')),
          );
        }

        // finalize nếu chưa finalize
        if (data['finalized'] != true) {
          // fire-and-forget
          BattleService.instance.finalizeAndRank(roomId);
        }

        final String? p1 = data['player1'];
        final String? p2 = data['player2'];
        final int s1 = (data['player1Score'] ?? 0) as int;
        final int s2 = (data['player2Score'] ?? 0) as int;
        final String? winner = data['winner'];

        String title;
        Color titleColor;

        if (winner == null) {
          title = '🤝 Hòa!';
          titleColor = Colors.amber;
        } else if (winner == me.uid) {
          title = '🏆 Bạn thắng!';
          titleColor = Colors.green;
        } else {
          title = '😢 Bạn thua';
          titleColor = Colors.redAccent;
        }

        final topic = (data['topic'] ?? '').toString();
        final p1Email = (data['player1Email'] ?? 'Người chơi 1').toString();
        final p2Email = (data['player2Email'] ?? 'Người chơi 2').toString();

        return Scaffold(
          appBar: AppBar(title: const Text('Kết quả thi đấu')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      )),
                  const SizedBox(height: 10),
                  if (topic.isNotEmpty)
                    Text('Chủ đề: $topic',
                        style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  _ScoreRow(label: p1Email, score: s1),
                  _ScoreRow(label: p2Email, score: s2),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.home),
                    label: const Text('Về trang chủ'),
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    ),
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

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;
  const _ScoreRow({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Text(':  $score',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}
