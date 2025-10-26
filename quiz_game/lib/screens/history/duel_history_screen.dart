import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DuelHistoryScreen extends StatelessWidget {
  const DuelHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử thi đấu ⚔️')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('duel_rooms')
            .where('status', isEqualTo: 'finished')
            .orderBy('finishedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['player1'] == uid || data['player2'] == uid;
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('Chưa có trận đấu nào.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final topic = data['topic'] ?? 'Chưa rõ';
              final p1 = data['player1Email'] ?? 'Người chơi 1';
              final p2 = data['player2Email'] ?? 'Người chơi 2';
              final s1 = data['player1Score'] ?? 0;
              final s2 = data['player2Score'] ?? 0;
              final winner = data['winner'];

              String result;
              if (winner == null) {
                result = '🤝 Hòa';
              } else if (winner == uid) {
                result = '🏆 Thắng';
              } else {
                result = '😢 Thua';
              }

              return ListTile(
                title: Text('Chủ đề: $topic'),
                subtitle: Text('$p1 ($s1) vs $p2 ($s2)'),
                trailing: Text(result),
              );
            },
          );
        },
      ),
    );
  }
}
