import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizService {
  // ✅ Hàm static giúp gọi dễ hơn
  static Future<void> saveQuizResult({
    required String topic,
    required int score,
    required int total,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('quiz_results').add({
      'userId': user.uid,
      'topic': topic,
      'score': score,
      'total': total,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
