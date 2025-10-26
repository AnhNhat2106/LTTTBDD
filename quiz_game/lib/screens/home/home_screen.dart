import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../ history/history_menu_screen.dart';
import '../quiz/topic_screen.dart';
import '../../services/auth_service.dart';
import '../profile/profile_screen.dart';
import '../rank/rank_screen.dart';
import '../rank/duel_screen.dart';

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
          // 🌗 Chuyển giao diện sáng/tối
          IconButton(
            icon: Icon(
              context.read<ThemeProvider>().isDark
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
            ),
            tooltip: 'Chuyển giao diện sáng/tối',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),

          // 👤 Hồ sơ cá nhân
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

          // 🚪 Đăng xuất (có xác nhận)
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      title: Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 28),
                          SizedBox(width: 10),
                          Text('Xác nhận đăng xuất'),
                        ],
                      ),
                      content: const Text(
                        'Bạn có chắc chắn muốn đăng xuất không?',
                        style: TextStyle(fontSize: 16),
                      ),
                      actions: [
                        TextButton(
                          child: const Text(
                            'Hủy',
                            style: TextStyle(color: Colors.grey),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
                  );
                },
              );

              if (confirm == true) {
                await AuthService().signOut();
              }
            },
          ),
        ],
      ),

      // 🧩 Nội dung chính
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
          final rankPoints = (data['rankPoints'] ?? 0).toInt();
          final wins = (data['wins'] ?? 0).toInt();
          final losses = (data['losses'] ?? 0).toInt();

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
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

                  // 👋 Lời chào
                  Text(
                    'Xin chào, $displayName',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🏅 Rank info
                  Card(
                    color: color.surface,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _rankStat('Điểm Rank', '$rankPoints', Icons.star),
                          _rankStat('Thắng', '$wins', Icons.check_circle),
                          _rankStat('Thua', '$losses', Icons.cancel),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ▶️ Luyện tập quiz
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TopicScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Luyện tập Quiz'),
                  ),
                  const SizedBox(height: 16),

                  // ⚔️ Thi đấu xếp hạng
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DuelScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.sports_esports),
                    label: const Text('Thi đấu xếp hạng'),
                  ),
                  const SizedBox(height: 16),

                  // 🏆 Bảng xếp hạng
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RankScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.leaderboard),
                    label: const Text('Bảng xếp hạng'),
                  ),
                  const SizedBox(height: 16),

                  // 📜 Lịch sử Quiz
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryMenuScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Lịch sử Quiz'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 Widget hiển thị thống kê Rank nhỏ
  Widget _rankStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }
}
