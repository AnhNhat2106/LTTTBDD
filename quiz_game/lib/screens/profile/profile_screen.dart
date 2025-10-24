import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final _picker = ImagePicker();

  final _name = TextEditingController();
  final _birthday = TextEditingController();
  String _gender = '';
  File? _image;
  String? _avatarUrl;

  bool _loading = true;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _name.text = (data['displayName'] ?? '').toString();
      _gender = (data['gender'] ?? '').toString();
      _birthday.text = (data['birthday'] ?? '').toString();
      _avatarUrl = (data['avatarUrl'] ?? '').toString();
    }
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<String?> _uploadAvatar(File file) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
      final uploadTask = ref.putFile(file);
      uploadTask.snapshotEvents.listen((event) {
        final total = event.totalBytes == 0 ? 1 : event.totalBytes;
        setState(() => _uploadProgress = event.bytesTransferred / total);
      });
      await uploadTask.whenComplete(() {});
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('❌ Lỗi upload: $e');
      return null;
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    String? url = _avatarUrl;
    if (_image != null) {
      url = await _uploadAvatar(_image!);
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': _name.text.trim(),
      'gender': _gender,
      'birthday': _birthday.text.trim(),
      'avatarUrl': url ?? '',
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu hồ sơ thành công')),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final init = _birthday.text.isNotEmpty
        ? DateFormat('dd/MM/yyyy').parse(_birthday.text)
        : DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
    );
    if (picked != null) {
      _birthday.text = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {});
    }
  }

  Future<void> _sendResetEmail() async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi email đổi mật khẩu')),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _birthday.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final avatarProvider = _image != null
        ? FileImage(_image!)
        : (_avatarUrl != null && _avatarUrl!.isNotEmpty
        ? NetworkImage(_avatarUrl!)
        : const AssetImage('assets/avatar_placeholder.png') as ImageProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: color.primary,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🖼 Ảnh đại diện + nút chỉnh sửa
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(radius: 60, backgroundImage: avatarProvider),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: FloatingActionButton.small(
                    heroTag: null,
                    backgroundColor: color.primary,
                    onPressed: _pickImage,
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                )
              ],
            ),
            if (_image != null && _uploadProgress > 0 && _uploadProgress < 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(value: _uploadProgress),
              ),
            const SizedBox(height: 20),

            // 🧾 Biệt danh
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Biệt danh (hiển thị)',
                prefixIcon: const Icon(Icons.badge_outlined),
                filled: true,
                fillColor: color.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 🚻 Giới tính
            DropdownButtonFormField<String>(
              value: _gender.isEmpty ? null : _gender,
              items: const [
                DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                DropdownMenuItem(value: 'Khác', child: Text('Khác')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? ''),
              decoration: InputDecoration(
                labelText: 'Giới tính',
                prefixIcon: const Icon(Icons.wc_outlined),
                filled: true,
                fillColor: color.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 🎂 Ngày sinh
            TextField(
              controller: _birthday,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: 'Ngày sinh (dd/MM/yyyy)',
                prefixIcon: const Icon(Icons.cake_outlined),
                filled: true,
                fillColor: color.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 💾 Nút lưu thay đổi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Lưu thay đổi'),
                onPressed: _save,
              ),
            ),
            const SizedBox(height: 12),

            // 🔐 Nút đổi mật khẩu
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.lock_reset_outlined),
                label: const Text('Gửi email đổi mật khẩu'),
                onPressed: _sendResetEmail,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
