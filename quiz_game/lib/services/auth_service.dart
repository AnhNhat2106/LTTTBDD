import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 🟦 Đăng ký tài khoản mới
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 🔹 Tạo document user mặc định trong Firestore
      await _db.collection('users').doc(cred.user!.uid).set({
        'email': email.trim(),
        'displayName': '',
        'avatarUrl': '',
        'gender': '',
        'birthday': '',
        // 🔹 Thêm các trường rank mặc định
        'rankPoints': 0,
        'wins': 0,
        'losses': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  /// 🟩 Đăng nhập
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 🔹 Khi user cũ đăng nhập, kiểm tra & thêm các field rank nếu thiếu
      final ref = _db.collection('users').doc(cred.user!.uid);
      final doc = await ref.get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final updates = <String, dynamic>{};

        if (!data.containsKey('rankPoints')) updates['rankPoints'] = 0;
        if (!data.containsKey('wins')) updates['wins'] = 0;
        if (!data.containsKey('losses')) updates['losses'] = 0;

        if (updates.isNotEmpty) {
          await ref.set(updates, SetOptions(merge: true));
        }
      }

      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  /// 📨 Gửi email khôi phục mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  /// 🔐 Đổi mật khẩu (khi đã đăng nhập)
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    } else {
      throw Exception('Bạn chưa đăng nhập!');
    }
  }

  /// 🧍‍♂️ Cập nhật hồ sơ người dùng (tên, ảnh)
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    File? photoFile,
  }) async {
    try {
      String? avatarUrl;

      // 🖼️ Upload ảnh nếu có
      if (photoFile != null) {
        final ref = _storage.ref().child('avatars/$uid.jpg');
        final uploadTask = await ref.putFile(photoFile);
        avatarUrl = await uploadTask.ref.getDownloadURL();
      }

      // 🔹 Cập nhật Firestore (và đảm bảo có rank fields)
      await _db.collection('users').doc(uid).set({
        if (displayName != null) 'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'rankPoints': FieldValue.increment(0),
        'wins': FieldValue.increment(0),
        'losses': FieldValue.increment(0),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Lỗi khi cập nhật hồ sơ: $e');
    }
  }

  /// 🔎 Lấy thông tin người dùng hiện tại
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  /// 🚪 Đăng xuất
  Future<void> signOut() async => _auth.signOut();

  /// ⚠️ Chuyển lỗi Firebase sang tiếng Việt
  Exception _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return Exception('Email không hợp lệ');
      case 'user-disabled':
        return Exception('Tài khoản đã bị vô hiệu hoá');
      case 'user-not-found':
        return Exception('Không tìm thấy tài khoản');
      case 'wrong-password':
        return Exception('Mật khẩu không đúng');
      case 'email-already-in-use':
        return Exception('Email đã được sử dụng');
      case 'weak-password':
        return Exception('Mật khẩu quá yếu (tối thiểu 6 ký tự)');
      case 'operation-not-allowed':
        return Exception('Tài khoản Email/Password chưa được bật trên Firebase');
      default:
        return Exception('Lỗi: ${e.message}');
    }
  }
}
