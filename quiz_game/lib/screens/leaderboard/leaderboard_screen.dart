import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('users')
        .orderBy('rankPoints', descending: true)
        .limit(50)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Bảng xếp hạng')),
      body: StreamBuilder<QuerySnapshot>(
        stream: q,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Chưa có dữ liệu xếp hạng'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final name = (d['displayName'] ?? d['email'] ?? 'Người chơi').toString();
              final avatarUrl = (d['avatarUrl'] ?? '').toString();
              final pts = (d['rankPoints'] ?? 0) as int;
              final wins = (d['wins'] ?? 0) as int;
              final losses = (d['losses'] ?? 0) as int;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty ? Text('${i + 1}') : null,
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Điểm: $pts · Thắng: $wins · Thua: $losses'),
                trailing: Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          );
        },
      ),
    );
  }
}
