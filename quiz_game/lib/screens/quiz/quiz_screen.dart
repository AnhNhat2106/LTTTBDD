import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/quiz_service.dart';
import '../quiz/result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String topicKey;
  final List<Map<String, dynamic>> questionList;
  final bool isDuel; // true = thi đấu, false = luyện tập

  const QuizScreen({
    super.key,
    required this.topicKey,
    required this.questionList,
    this.isDuel = false,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int perQuestionSeconds = 15;

  late final List<Map<String, dynamic>> _questions; // đã shuffle thứ tự
  int currentIndex = 0;
  int score = 0;
  int? selectedIndex;
  bool isAnswered = false;

  int remain = perQuestionSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 🔀 Random thứ tự câu hỏi, KHÔNG đổi thứ tự options để không sai index answer
    _questions = List<Map<String, dynamic>>.from(widget.questionList);
    _questions.shuffle(Random());

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => remain = perQuestionSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (remain <= 1) {
        t.cancel();
        _autoNextWhenTimeout();
      } else {
        setState(() => remain--);
      }
    });
  }

  Future<void> _autoNextWhenTimeout() async {
    if (!isAnswered) {
      setState(() {
        isAnswered = true;
        selectedIndex = null;
      });
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _goNextOrFinish();
  }

  Future<void> _goNextOrFinish() async {
    if (currentIndex < _questions.length - 1) {
      setState(() {
        currentIndex++;
        isAnswered = false;
        selectedIndex = null;
      });
      _startTimer();
      return;
    }

    // Hết câu hỏi
    _timer?.cancel();

    if (widget.isDuel) {
      // PvP: trả điểm về màn hình gọi
      if (mounted) Navigator.pop(context, score);
      return;
    }

    // PvE: lưu lịch sử + mở ResultScreen
    await QuizService.saveQuizResult(
      topic: widget.topicKey,
      score: score,
      total: _questions.length,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          topicKey: widget.topicKey,
          score: score,
          total: _questions.length,
        ),
      ),
    );
  }

  void checkAnswer(int index) async {
    if (isAnswered) return;
    final correctIndex = _questions[currentIndex]['answer'];
    setState(() {
      selectedIndex = index;
      isAnswered = true;
      if (index == correctIndex) score++;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    _goNextOrFinish();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    final question = _questions[currentIndex];
    final total = _questions.length;
    final progress = (currentIndex + 1) / total;
    final correctIndex = question['answer'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.isDuel ? 'Thi đấu - ${widget.topicKey}' : 'Quiz - ${widget.topicKey}'),
        backgroundColor: color.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 18),
                const SizedBox(width: 6),
                Text('$remain s', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: progress,
              color: color.primary,
              backgroundColor: color.primary.withOpacity(.2),
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 22),
            ...List.generate(question['options'].length, (index) {
              final optionText = question['options'][index];
              Color? btnColor;

              if (isAnswered) {
                if (index == correctIndex) {
                  btnColor = Colors.green.shade500;
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
                    foregroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
