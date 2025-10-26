import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/home_screen.dart';

class BattleResultScreen extends StatelessWidget {
  final String roomId;
  const BattleResultScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả thi đấu ⚔️')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('duel_rooms').doc(roomId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();
          if (data == null) return const Center(child: Text('Không tìm thấy dữ liệu'));

          final topic = data['topic'] ?? 'Chưa rõ';
          final p1Email = data['player1Email'] ?? 'Người chơi 1';
          final p2Email = data['player2Email'] ?? 'Người chơi 2';
          final s1 = data['player1Score'] ?? 0;
          final s2 = data['player2Score'] ?? 0;
          final p1 = data['player1'];
          final p2 = data['player2'];
          final winner = data['winner'];

          String resultText;
          Color resultColor;

          if (winner == null) {
            resultText = '🤝 Trận đấu kết thúc: HÒA';
            resultColor = Colors.amber;
          } else if (winner == uid) {
            resultText = '🏆 Bạn THẮNG!';
            resultColor = Colors.green;
          } else {
            resultText = '😢 Bạn THUA';
            resultColor = Colors.redAccent;
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(resultText,
                      style: TextStyle(
                          color: resultColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24)),
                  const SizedBox(height: 20),
                  Text('Chủ đề: $topic', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text('$p1Email: $s1 điểm'),
                  Text('$p2Email: $s2 điểm'),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.home),
                    label: const Text("Về trang chủ"),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
