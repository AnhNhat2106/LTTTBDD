import 'dart:async';
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

  late Timer _timer;
  int timeLeft = 10; // ⏱ số giây cho mỗi câu

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        _nextQuestion(autoSkip: true);
      }
    });
  }

  void checkAnswer(int index) async {
    if (isAnswered) return;

    final correctIndex = widget.questionList[currentIndex]['answer'];
    setState(() {
      selectedIndex = index;
      isAnswered = true;
      if (index == correctIndex) score++;
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    _nextQuestion();
  }

  void _nextQuestion({bool autoSkip = false}) async {
    _timer.cancel();

    if (currentIndex < widget.questionList.length - 1) {
      setState(() {
        currentIndex++;
        isAnswered = false;
        selectedIndex = null;
        timeLeft = 10; // reset timer cho câu mới
      });
      _startTimer();
    } else {
      // ✅ Lưu kết quả (chế độ luyện tập)
      await QuizService.saveQuizResult(
        topic: widget.topicKey,
        score: score,
        total: widget.questionList.length,
      );

      // ✅ Trả điểm về DuelScreen nếu có (PvP)
      if (Navigator.canPop(context)) {
        Navigator.pop(context, score);
      }

      // ✅ Hiển thị kết quả cá nhân
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
  void dispose() {
    _timer.cancel();
    super.dispose();
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
            // 🧭 Tiến độ câu hỏi
            LinearProgressIndicator(
              value: progress,
              color: color.primary,
              backgroundColor: color.primary.withOpacity(.2),
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 10),

            // ⏳ Thanh thời gian đếm ngược
            Stack(
              alignment: Alignment.center,
              children: [
                LinearProgressIndicator(
                  value: timeLeft / 10,
                  minHeight: 10,
                  color: timeLeft > 3 ? Colors.green : Colors.red,
                  backgroundColor: Colors.grey.shade300,
                ),
                Text(
                  "$timeLeft giây",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: timeLeft > 3 ? Colors.black : Colors.redAccent,
                  ),
                ),
              ],
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
