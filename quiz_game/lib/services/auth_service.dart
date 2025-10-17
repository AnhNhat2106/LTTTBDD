import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _db.collection('users').doc(cred.user!.uid).set({
        'email': email.trim(),
        'displayName': '',
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    } else {
      throw Exception('Chưa đăng nhập!');
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    File? photoFile,
  }) async {
    try {
      String? photoUrl;

      if (photoFile != null) {
        final ref = _storage.ref().child('avatars/$uid.jpg');
        await ref.putFile(photoFile);
        photoUrl = await ref.getDownloadURL();
      }

      await _db.collection('users').doc(uid).update({
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Lỗi khi cập nhật hồ sơ: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> signOut() async => _auth.signOut();

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
        return Exception('Mật khẩu quá yếu (>= 6 ký tự)');
      case 'operation-not-allowed':
        return Exception('Provider chưa được bật (hãy bật Email/Password)');
      default:
        return Exception('Lỗi: ${e.message}');
    }
  }
}
