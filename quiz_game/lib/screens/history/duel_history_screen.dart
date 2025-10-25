import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/quiz_service.dart';

class DuelHistoryScreen extends StatelessWidget {
  const DuelHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Lịch sử thi đấu ⚔️'),
        backgroundColor: color.primary,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: QuizService.getUserDuelHistory(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có trận đấu nào.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final docs = snap.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final topic = (data['topic'] ?? 'Không rõ').toString();
              final p1Email = (data['player1Email'] ?? 'Người chơi 1').toString();
              final p2Email = (data['player2Email'] ?? 'Người chơi 2').toString();
              final s1 = data['player1Score'] ?? 0;
              final s2 = data['player2Score'] ?? 0;
              final winner = data['winner'];
              final ts = data['finishedAt'];
              final finishedAt =
              (ts is Timestamp) ? DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate()) : '';

              // Xác định kết quả của người chơi hiện tại
              final iAmWinner = (winner == null)
                  ? null
                  : (winner == me.uid
                  ? true
                  : (winner != me.uid ? false : null));

              final Color statusColor;
              final String statusText;

              if (iAmWinner == null) {
                statusColor = Colors.grey;
                statusText = 'Hoà';
              } else if (iAmWinner) {
                statusColor = Colors.greenAccent.shade400;
                statusText = 'Thắng';
              } else {
                statusColor = Colors.redAccent.shade200;
                statusText = 'Thua';
              }

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
                    leading: _ScoreBadge(
                      s1: s1,
                      s2: s2,
                      color: statusColor,
                    ),
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
                      '$p1Email: $s1 điểm\n$p2Email: $s2 điểm\n$finishedAt',
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
            },
          );
        },
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int s1, s2;
  final Color color;

  const _ScoreBadge({required this.s1, required this.s2, required this.color});

  @override
  Widget build(BuildContext context) {
    final total = s1 + s2;
    final text = total > 0 ? '$s1:$s2' : '--';
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
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
