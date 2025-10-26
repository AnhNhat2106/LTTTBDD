import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DuelHistoryScreen extends StatelessWidget {
  const DuelHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử thi đấu ⚔️'),
        backgroundColor: theme.colorScheme.primary,
      ),
      backgroundColor: const Color(0xFFE8F0FE),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('duel_rooms')
            .where('status', isEqualTo: 'finished')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có trận đấu nào.'));
          }

          final docs = snapshot.data!.docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['player1'] == uid || data['player2'] == uid;
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('Chưa có trận đấu nào.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final topic = data['topic'] ?? 'Chưa rõ';
              final p1 = data['player1Email'] ?? 'Người chơi 1';
              final p2 = data['player2Email'] ?? 'Người chơi 2';
              final s1 = data['player1Score'] ?? 0;
              final s2 = data['player2Score'] ?? 0;
              final winner = data['winner'];
              final ts = (data['finishedAt'] as Timestamp?)?.toDate();

              String result;
              Color resultColor;
              IconData icon;

              if (winner == null) {
                result = 'Hòa';
                resultColor = Colors.amber[800]!;
                icon = Icons.handshake;
              } else if (winner == uid) {
                result = 'Thắng';
                resultColor = Colors.green[700]!;
                icon = Icons.emoji_events;
              } else {
                result = 'Thua';
                resultColor = Colors.red[700]!;
                icon = Icons.sentiment_dissatisfied;
              }

              final timeText = ts != null
                  ? DateFormat('dd/MM/yyyy – HH:mm').format(ts)
                  : 'Chưa rõ';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📘 Chủ đề: $topic',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('🧑‍🤝‍🧑 $p1 ($s1)'),
                      Text('⚔️ $p2 ($s2)'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: resultColor, size: 22),
                              const SizedBox(width: 6),
                              Text(
                                result,
                                style: TextStyle(
                                  color: resultColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: Colors.grey, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                timeText,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
