import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử Quiz'),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quiz_results')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có kết quả nào'));
          }

          final docs = snap.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;

              final int score = (data['score'] ?? 0) as int;
              final int total = (data['total'] ?? 0) as int;
              final String topic = (data['topic'] ?? 'Chưa rõ').toString();

              DateTime? time;
              final ts = data['createdAt'];
              if (ts is Timestamp) time = ts.toDate();

              final ratio = total == 0 ? 0.0 : score / total;
              final status = _statusFromRatio(ratio);

              return _ResultTile(
                topic: topic,
                score: score,
                total: total,
                time: time,
                status: status,
              );
            },
          );
        },
      ),
    );
  }
}

/// 3 mức đánh giá để tô màu và text
enum _Status { good, medium, bad }

_Status _statusFromRatio(double r) {
  if (r >= 0.8) return _Status.good;   // ≥ 80%: Giỏi
  if (r >= 0.5) return _Status.medium; // 50–79%: Khá
  return _Status.bad;                  // < 50%: Cần cố gắng
}

class _ResultTile extends StatelessWidget {
  final String topic;
  final int score;
  final int total;
  final DateTime? time;
  final _Status status;

  const _ResultTile({
    required this.topic,
    required this.score,
    required this.total,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      _Status.good => Colors.green,
      _Status.medium => Colors.orange,
      _Status.bad => Colors.red,
    };

    final String statusText = switch (status) {
      _Status.good => 'Giỏi',
      _Status.medium => 'Khá',
      _Status.bad => 'Cần cố gắng',
    };

    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(.08), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: _ScoreBadge(score: score, total: total, color: color),
          title: Text(
            'Chủ đề: $topic',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Điểm: $score/$total · ${time != null ? DateFormat('dd/MM/yyyy HH:mm').format(time!) : 'Không rõ thời gian'}',
          ),
          trailing: Chip(
            label: Text(statusText),
            backgroundColor: color.withOpacity(.12),
            labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
            side: BorderSide(color: color.withOpacity(.3)),
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score, total;
  final Color color;

  const _ScoreBadge({
    required this.score,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withOpacity(.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$score/$total',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
