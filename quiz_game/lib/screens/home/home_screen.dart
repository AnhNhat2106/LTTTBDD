import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../quiz/topic_screen.dart';
import '../quiz/history_screen.dart';
import '../../services/auth_service.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            tooltip: 'Trang cá nhân',
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),

      // 🧠 Hiển thị avatar + biệt danh bằng Firestore Stream
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final avatarUrl = data['avatarUrl'] ?? '';
          final displayName = data['displayName'] ?? user?.email ?? '(Người dùng)';

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🧍‍♂️ Avatar
                CircleAvatar(
                  radius: 45,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : const AssetImage('assets/avatar_placeholder.png')
                  as ImageProvider,
                ),
                const SizedBox(height: 12),

                // 👋 Biệt danh hoặc email
                Text(
                  'Xin chào, $displayName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 40),

                // ▶️ Nút bắt đầu quiz
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TopicScreen()),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Bắt đầu chơi Quiz'),
                ),

                const SizedBox(height: 20),

                // ⏳ Nút xem lịch sử
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side:
                    BorderSide(color: Colors.purple.shade200, width: 2),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HistoryScreen()),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Xem lịch sử Quiz'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
