import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import 'topics.dart';


class TopicScreen extends StatelessWidget {
  const TopicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chọn chủ đề Quiz"),
        backgroundColor: Colors.purple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: topics.entries.map((entry) {
          final topicKey = entry.key; // "Lịch sử", "CNTT", "Toán học"
          final topicValue = entry.value; // danh sách câu hỏi

          return Card(
            child: ListTile(
              title: Text(
                topicKey,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                final topicQuestions = topics[topicKey]; // ✅ Lấy danh sách câu hỏi từ topics.dart

                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => QuizScreen(
                      topicKey: topicKey,
                      questionList: topicQuestions ?? [], // ✅ tránh null
                    ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      return SlideTransition(position: animation.drive(tween), child: child);
                    },
                  ),
                );
              },

            ),
          );
        }).toList(),
      ),
    );
  }
}
