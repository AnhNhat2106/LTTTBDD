import 'package:flutter/material.dart';
import 'package:quiz_game/screens/home/home_screen.dart';
import '../ history/duel_history_screen.dart';

class BattleResultScreen extends StatelessWidget {
  final String topic;
  final String myEmail;
  final String oppEmail;
  final int myScore;
  final int oppScore;
  final int myTotal;
  final int oppTotal;
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
    String title;
    String rankChange;
    Color color;
    IconData icon;

    if (isMeWinner == null) {
      title = "🤝 Trận đấu kết thúc: HÒA";
      rankChange = "+2 điểm rank";
      color = Colors.amber;
      icon = Icons.handshake;
    } else if (isMeWinner == true) {
      title = "🏆 Bạn THẮNG!";
      rankChange = "+10 điểm rank";
      color = Colors.green;
      icon = Icons.emoji_events;
    } else {
      title = "😢 Bạn THUA!";
      rankChange = "-5 điểm rank";
      color = Colors.redAccent;
      icon = Icons.sentiment_dissatisfied;
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        title: const Text('Kết quả thi đấu'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 90, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Chủ đề: $topic",
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const Divider(height: 32, thickness: 1, color: Colors.white24),
              _playerScore("Bạn", myEmail, myScore, myTotal, Colors.lightBlueAccent),
              const SizedBox(height: 8),
              _playerScore("Đối thủ", oppEmail, oppScore, oppTotal, Colors.orangeAccent),
              const Divider(height: 32, thickness: 1, color: Colors.white24),
              Text(
                rankChange,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text("Xem lịch sử thi đấu"),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DuelHistoryScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerScore(
      String label, String email, int score, int total, Color color) {
    return Column(
      children: [
        Text(
          "$label: $email",
          style: const TextStyle(color: Colors.white70, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        Text(
          "$score / $total",
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
