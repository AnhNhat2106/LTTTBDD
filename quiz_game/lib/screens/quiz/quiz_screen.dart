import 'package:flutter/material.dart';
import '../../services/quiz_service.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String topicKey; // tên chủ đề (ví dụ: 'Lịch sử', 'CNTT')
  final List<Map<String, dynamic>> questionList; // danh sách câu hỏi

  const QuizScreen({
    super.key,
    required this.topicKey,
    required this.questionList,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  int score = 0;
  int? selectedIndex;
  bool isAnswered = false;

  void checkAnswer(int index) async {
    if (isAnswered) return;

    final correctIndex = widget.questionList[currentIndex]['answer'];
    setState(() {
      selectedIndex = index;
      isAnswered = true;
      if (index == correctIndex) score++;
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (currentIndex < widget.questionList.length - 1) {
      setState(() {
        currentIndex++;
        isAnswered = false;
        selectedIndex = null;
      });
    } else {
      // ✅ Lưu kết quả (chỉ dành cho chế độ luyện tập)
      await QuizService.saveQuizResult(
        topic: widget.topicKey,
        score: score,
        total: widget.questionList.length,
      );

      // ✅ Trả điểm về cho DuelScreen (PvP)
      if (Navigator.canPop(context)) {
        Navigator.pop(context, score);
      }

      // ✅ Hiển thị màn hình kết quả cá nhân
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              topicKey: widget.topicKey,
              score: score,
              total: widget.questionList.length,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final question = widget.questionList[currentIndex];
    final total = widget.questionList.length;
    final progress = (currentIndex + 1) / total;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Quiz - ${widget.topicKey}"),
        backgroundColor: color.primary,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🧭 Thanh tiến độ
            LinearProgressIndicator(
              value: progress,
              color: color.primary,
              backgroundColor: color.primary.withOpacity(.2),
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 20),

            // 🧩 Thông tin câu hỏi
            Text(
              "Câu ${currentIndex + 1}/$total",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              question['question'],
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 25),

            // 🔘 Các lựa chọn
            ...List.generate(question['options'].length, (index) {
              final optionText = question['options'][index];
              final correctIndex = question['answer'];
              Color? btnColor;

              if (isAnswered) {
                if (index == correctIndex) {
                  btnColor = Colors.green.shade400;
                } else if (index == selectedIndex && selectedIndex != correctIndex) {
                  btnColor = Colors.red.shade400;
                } else {
                  btnColor = theme.brightness == Brightness.dark
                      ? color.surface
                      : Colors.grey.shade200;
                }
              } else {
                btnColor = theme.brightness == Brightness.dark
                    ? color.surface
                    : color.secondary.withOpacity(.1);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    foregroundColor: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () => checkAnswer(index),
                  child: Text(
                    optionText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
