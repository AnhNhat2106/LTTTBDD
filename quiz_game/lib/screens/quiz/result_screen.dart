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
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    final percent = (score / total * 100).toStringAsFixed(1);

    // 🎯 Xác định màu kết quả (xanh nếu cao, vàng nếu trung bình, đỏ nếu thấp)
    Color resultColor;
    if (score / total >= 0.8) {
      resultColor = Colors.greenAccent.shade400;
    } else if (score / total >= 0.5) {
      resultColor = Colors.amberAccent.shade400;
    } else {
      resultColor = Colors.redAccent.shade200;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🏆 Icon chiến thắng
              Icon(
                Icons.emoji_events,
                size: 100,
                color: resultColor,
              ),
              const SizedBox(height: 20),

              // 🎉 Tiêu đề
              Text(
                "Hoàn thành Quiz!",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // 🧩 Chủ đề
              Text(
                "Chủ đề: $topicKey",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              // 📊 Điểm số
              Text(
                "Điểm của bạn: $score / $total",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: 8),

              // 📈 Tỷ lệ đúng
              Text(
                "Tỷ lệ đúng: $percent%",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: color.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 40),

              // 🔁 Nút chơi lại
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.restart_alt),
                  label: const Text("Chơi lại"),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const TopicScreen()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 🏠 Nút về trang chủ
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.home_outlined),
                  label: const Text("Về trang chủ"),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
