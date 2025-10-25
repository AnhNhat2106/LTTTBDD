import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import 'topic_screen.dart';

class ResultScreen extends StatelessWidget {
  final String topicKey;
  final int score;
  final int total;

  const ResultScreen({
    super.key,
    required this.topicKey,
    required this.score,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (score / total * 100).toStringAsFixed(1);
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 100, color: Colors.green.shade400),
              const SizedBox(height: 16),
              Text(
                "Hoàn thành Quiz!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text("Chủ đề: $topicKey", style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                "Điểm của bạn: $score / $total",
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text("Tỷ lệ đúng: $percent%"),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.restart_alt),
                label: const Text("Chơi lại"),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const TopicScreen()),
                  );
                },
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
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
      ),
    );
  }
}
