import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// 🧠 Lưu kết quả Quiz của người dùng hiện tại (chế độ luyện tập)
  static Future<void> saveQuizResult({
    required String topic,
    required int score,
    required int total,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final double percent = total > 0 ? (score / total * 100) : 0;

      await _db.collection('quiz_results').add({
        'userId': user.uid,
        'email': user.email ?? '',
        'topic': topic,
        'score': score,
        'total': total,
        'percent': percent.toStringAsFixed(1),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Quiz result saved successfully for $topic');
    } catch (e) {
      print('❌ Lỗi khi lưu kết quả quiz: $e');
    }
  }

  /// 📄 Lấy lịch sử quiz của người dùng hiện tại (luyện tập - PvE)
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserQuizHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _db
        .collection('quiz_results')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ⚔️ Lấy lịch sử thi đấu PvP của người dùng hiện tại
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserDuelHistory() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    try {
      // yêu cầu SDK Firestore >= 4.9
      return _db
          .collection('duel_rooms')
          .where('status', isEqualTo: 'finished')
          .where(Filter.or(
        Filter('player1', isEqualTo: user.uid),
        Filter('player2', isEqualTo: user.uid),
      ))
          .orderBy('finishedAt', descending: true)
          .snapshots();
    } catch (e) {
      print('❌ Lỗi khi truy vấn lịch sử PvP: $e');
      return const Stream.empty();
    }
  }

  /// 🧹 Xoá tất cả kết quả quiz luyện tập của user (tuỳ chọn)
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
