import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Lịch sử Quiz'),
        backgroundColor: color.primary,
        elevation: 2,
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
            return Center(
              child: Text(
                'Chưa có kết quả nào',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
            );
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

/// 3 mức đánh giá
enum _Status { good, medium, bad }

_Status _statusFromRatio(double r) {
  if (r >= 0.8) return _Status.good;
  if (r >= 0.5) return _Status.medium;
  return _Status.bad;
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
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    final Color statusColor = switch (status) {
      _Status.good => Colors.greenAccent.shade400,
      _Status.medium => Colors.amber.shade400,
      _Status.bad => Colors.redAccent.shade200,
    };

    final String statusText = switch (status) {
      _Status.good => 'Giỏi',
      _Status.medium => 'Khá',
      _Status.bad => 'Cần cố gắng',
    };

    return Card(
      color: color.surface,
      elevation: 3,
      shadowColor: statusColor.withOpacity(.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(.06),
              theme.brightness == Brightness.dark
                  ? color.surface.withOpacity(.9)
                  : Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: _ScoreBadge(score: score, total: total, color: statusColor),
          title: Text(
            'Chủ đề: $topic',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          subtitle: Text(
            'Điểm: $score/$total · ${time != null ? DateFormat('dd/MM/yyyy HH:mm').format(time!) : 'Không rõ thời gian'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
          trailing: Chip(
            label: Text(statusText),
            backgroundColor: statusColor.withOpacity(.12),
            labelStyle: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(color: statusColor.withOpacity(.3)),
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
          colors: [color, color.withOpacity(.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$score/$total',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
