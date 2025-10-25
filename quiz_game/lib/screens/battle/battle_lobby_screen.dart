import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/battle_service.dart';
import '../quiz/topics.dart';
import 'battle_quiz_screen.dart';

class BattleLobbyScreen extends StatefulWidget {
  const BattleLobbyScreen({super.key});

  @override
  State<BattleLobbyScreen> createState() => _BattleLobbyScreenState();
}

class _BattleLobbyScreenState extends State<BattleLobbyScreen> {
  String? _selectedTopic;
  String? _roomId;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _roomStream;

  Future<void> _match() async {
    if (_selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn chủ đề trước đã')),
      );
      return;
    }
    final id = await BattleService.instance.autoMatchOrCreate(topic: _selectedTopic!);
    setState(() {
      _roomId = id;
      _roomStream = BattleService.instance.watchRoom(id);
    });
  }

  void _goPlay(String topic, String roomId) {
    final qs = topics[topic] ?? [];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BattleQuizScreen(roomId: roomId, topicKey: topic, questionList: qs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topicKeys = topics.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thi đấu xếp hạng ⚔️'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _roomId == null
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Chọn chủ đề', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTopic,
              items: topicKeys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: (v) => setState(() => _selectedTopic = v),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.sports_esports),
              label: const Text('Tìm trận / Tạo phòng'),
              onPressed: _match,
            ),
          ],
        )
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _roomStream,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data!.data();
            if (data == null) {
              return const Center(child: Text('Phòng đã xoá hoặc không tồn tại'));
            }
            final status = (data['status'] ?? 'waiting') as String;
            final topic = (data['topic'] ?? '') as String;

            if (status == 'waiting') {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Đang chờ người chơi khác...'),
                  ],
                ),
              );
            }

            if (status == 'playing') {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Đã ghép trận!'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      child: const Text('Vào thi đấu'),
                      onPressed: () => _goPlay(topic, _roomId!),
                    ),
                  ],
                ),
              );
            }

            if (status == 'finished') {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Trận đấu đã kết thúc'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
