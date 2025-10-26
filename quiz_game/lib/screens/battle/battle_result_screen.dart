import 'package:flutter/material.dart';

class BattleResultScreen extends StatelessWidget {
  final String topic;
  final String myEmail;
  final String oppEmail;
  final int myScore;
  final int oppScore;
  final int myTotal;
  final int oppTotal;
  /// null = Hòa, true = bạn thắng, false = bạn thua
  final bool? isMeWinner;

  const BattleResultScreen({
    super.key,
    required this.topic,
    required this.myEmail,
    required this.oppEmail,
    required this.myScore,
    required this.oppScore,
    required this.myTotal,
    required this.oppTotal,
    required this.isMeWinner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title;
    IconData icon;
    Color iconColor;

    if (isMeWinner == null) {
      title = '🤝 Hòa!';
      icon = Icons.handshake;
      iconColor = Colors.amber;
    } else if (isMeWinner!) {
      title = '🏆 Bạn thắng!';
      icon = Icons.emoji_events;
      iconColor = Colors.green;
    } else {
      title = '😢 Bạn thua';
      icon = Icons.sentiment_dissatisfied;
      iconColor = Colors.redAccent;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả thi đấu')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 96, color: iconColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Chủ đề: $topic'),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Bạn', myEmail),
                      _row('Đối thủ', oppEmail),
                      const Divider(height: 20),
                      _row('Điểm của bạn', '$myScore / $myTotal'),
                      _row('Điểm đối thủ', '$oppScore / $oppTotal'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Về trang chủ'),
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String l, String r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(l)),
          Text(
            r,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
