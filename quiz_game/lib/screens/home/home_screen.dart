import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../quiz/topic_screen.dart';
import '../quiz/history_screen.dart';
import '../../services/auth_service.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: color.primary,
        actions: [
          // 🌗 Nút chuyển giao diện
          IconButton(
            icon: Icon(
              context.read<ThemeProvider>().isDark
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
            ),
            tooltip: 'Chuyển giao diện sáng/tối',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),

          // 👤 Nút hồ sơ
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

          // 🚪 Nút đăng xuất
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),

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
          final displayName =
              data['displayName'] ?? user?.email ?? '(Người dùng)';

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
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // ▶️ Nút bắt đầu quiz
                ElevatedButton.icon(
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
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
