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

      // Theo dõi tiến trình
      uploadTask.snapshotEvents.listen((event) {
        final total = event.totalBytes == 0 ? 1 : event.totalBytes;
        setState(() => _uploadProgress = event.bytesTransferred / total);
      });

      await uploadTask.whenComplete(() {});
      final url = await ref.getDownloadURL();
      print('✅ Upload thành công: $url');
      return url;
    } catch (e) {
      print('❌ Lỗi upload: $e');
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
        const SnackBar(content: Text('Đã lưu hồ sơ')),
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final avatarProvider = _image != null
        ? FileImage(_image!)
        : (_avatarUrl != null && _avatarUrl!.isNotEmpty
        ? NetworkImage(_avatarUrl!)
        : const AssetImage('assets/avatar_placeholder.png') as ImageProvider);

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(radius: 60, backgroundImage: avatarProvider),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: FloatingActionButton.small(
                    heroTag: 'edit_avatar',
                    backgroundColor: Colors.purple,
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
            const SizedBox(height: 16),

            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Biệt danh (hiển thị)',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _gender.isEmpty ? null : _gender,
              items: const [
                DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                DropdownMenuItem(value: 'Khác', child: Text('Khác')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? ''),
              decoration: const InputDecoration(
                labelText: 'Giới tính',
                prefixIcon: Icon(Icons.wc),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _birthday,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Ngày sinh (dd/MM/yyyy)',
                prefixIcon: Icon(Icons.cake),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Lưu thay đổi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _save,
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.lock_reset),
              label: const Text('Gửi email đổi mật khẩu'),
              onPressed: _sendResetEmail,
            ),
          ],
        ),
      ),
    );
  }
}
