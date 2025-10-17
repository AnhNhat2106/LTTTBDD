import 'package:flutter/material.dart';
import '../../services/quiz_service.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String topicKey; // tên chủ đề (ví dụ: 'Lịch sử', 'CNTT')
  final List<Map<String, dynamic>> questionList; // danh sách câu hỏi theo chủ đề

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

  void checkAnswer(int selectedIndex) {
    // kiểm tra đáp án đúng
    if (selectedIndex == widget.questionList[currentIndex]['answer']) {
      score++;
    }

    // nếu chưa hết câu hỏi -> sang câu tiếp theo
    if (currentIndex < widget.questionList.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      // hết câu hỏi -> lưu kết quả + hiển thị thông báo
      QuizService.saveQuizResult(
        topic: widget.topicKey,
        score: score,
        total: widget.questionList.length,
      );


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

  @override
  Widget build(BuildContext context) {
    final question = widget.questionList[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Quiz - ${widget.topicKey}"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Câu ${currentIndex + 1}/${widget.questionList.length}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              question['question'],
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ...List.generate(question['options'].length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade100,
                    foregroundColor: Colors.purple.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => checkAnswer(index),
                  child: Text(
                    question['options'][index],
                    textAlign: TextAlign.center,
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
