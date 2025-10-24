import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// 🧠 Lưu kết quả Quiz của người dùng hiện tại
  static Future<void> saveQuizResult({
    required String topic,
    required int score,
    required int total,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 🔹 Tính phần trăm đúng
      final double percent = total > 0 ? (score / total * 100) : 0;

      // 🔹 Ghi dữ liệu vào Firestore
      await _db.collection('quiz_results').add({
        'userId': user.uid,
        'email': user.email ?? '',
        'topic': topic,
        'score': score,
        'total': total,
        'percent': percent.toStringAsFixed(1), // ví dụ: "83.3"
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Quiz result saved successfully for $topic');
    } catch (e) {
      print('❌ Lỗi khi lưu kết quả quiz: $e');
    }
  }

  /// 📄 Lấy lịch sử quiz của người dùng hiện tại (sắp xếp mới nhất)
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserQuizHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      // Trả về stream rỗng nếu chưa đăng nhập
      return const Stream.empty();
    }

    return _db
        .collection('quiz_results')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 🧹 Xoá tất cả kết quả quiz của user (tuỳ chọn)
  static Future<void> clearUserHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _db
          .collection('quiz_results')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('🧹 Đã xoá toàn bộ lịch sử quiz của người dùng.');
    } catch (e) {
      print('❌ Lỗi khi xoá lịch sử quiz: $e');
    }
  }
}
