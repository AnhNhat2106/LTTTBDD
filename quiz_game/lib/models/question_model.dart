class Question {
  final String questionText; // nội dung câu hỏi
  final List<String> options; // các lựa chọn
  final int correctIndex; // chỉ số đáp án đúng (0, 1, 2, 3)

  Question({
    required this.questionText,
    required this.options,
    required this.correctIndex,
  });
}
