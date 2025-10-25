import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RankScreen extends StatelessWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('🏆 Bảng xếp hạng'),
        backgroundColor: color.primary,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('rankPoints', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có người chơi nào.'));
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['displayName']?.toString().trim();
              final avatar = data['avatarUrl']?.toString() ?? '';
              final rankPoints = (data['rankPoints'] ?? 0).toInt();
              final wins = (data['wins'] ?? 0).toInt();
              final losses = (data['losses'] ?? 0).toInt();

              // Xác định màu và icon cho top đầu
              IconData medalIcon;
              Color medalColor;
              switch (index) {
                case 0:
                  medalIcon = Icons.emoji_events;
                  medalColor = Colors.amber;
                  break;
                case 1:
                  medalIcon = Icons.emoji_events;
                  medalColor = Colors.grey;
                  break;
                case 2:
                  medalIcon = Icons.emoji_events;
                  medalColor = Colors.brown;
                  break;
                default:
                  medalIcon = Icons.star_border;
                  medalColor = Colors.blueGrey;
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
                child: ListTile(
                  leading: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundImage: avatar.isNotEmpty
                            ? NetworkImage(avatar)
                            : const AssetImage('assets/avatar_placeholder.png')
                        as ImageProvider,
                      ),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white,
                        child: Icon(
                          medalIcon,
                          color: medalColor,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    name?.isNotEmpty == true ? name! : 'Người chơi ${index + 1}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '🏅 $rankPoints điểm  •  ⚔️ $wins thắng  •  💀 $losses thua',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
