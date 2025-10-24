import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import 'topics.dart';

class TopicScreen extends StatelessWidget {
  const TopicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Chọn chủ đề Quiz"),
        backgroundColor: color.primary,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: topics.entries.map((entry) {
          final topicKey = entry.key; // ví dụ: "Lịch sử", "CNTT", "Toán học"
          final topicValue = entry.value; // danh sách câu hỏi

          return Card(
            color: color.surface, // tự đổi sáng/tối
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              title: Text(
                topicKey,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: color.primary),
              onTap: () {
                final topicQuestions = topics[topicKey];

                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => QuizScreen(
                      topicKey: topicKey,
                      questionList: topicQuestions ?? [],
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
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
