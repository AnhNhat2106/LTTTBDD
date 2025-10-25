import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../quiz/topics.dart';
import '../quiz/quiz_screen.dart';

class DuelScreen extends StatefulWidget {
  const DuelScreen({super.key});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  String? selectedTopic;
  bool isSearching = false;
  bool isMatched = false;
  String statusText = 'Chọn chủ đề để thi đấu';
  String? opponentName;
  String? roomId;

  final user = FirebaseAuth.instance.currentUser!;
  final _db = FirebaseFirestore.instance;

  /// 🔹 Tìm hoặc tạo phòng thi đấu
  Future<void> _findOpponent() async {
    if (selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn chủ đề trước khi thi đấu!')),
      );
      return;
    }

    setState(() {
      isSearching = true;
      statusText = '🔍 Đang tìm đối thủ...';
    });

    // 1️⃣ Tìm phòng đang "waiting" cùng chủ đề
    final waitingRooms = await _db
        .collection('duel_rooms')
        .where('topic', isEqualTo: selectedTopic)
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (waitingRooms.docs.isNotEmpty) {
      // 2️⃣ Ghép vào phòng có sẵn
      final room = waitingRooms.docs.first.reference;
      roomId = room.id;

      await room.update({
        'player2': user.uid,
        'player2Email': user.email,
        'status': 'matched', // ✅ chuyển sang trạng thái matched (đang chờ xác nhận)
      });

      setState(() {
        statusText = '🥳 Tìm thấy đối thủ, đang chờ xác nhận...';
      });

      _listenToRoom(room.id);
    } else {
      // 3️⃣ Không có phòng -> tạo mới
      final newRoom = await _db.collection('duel_rooms').add({
        'topic': selectedTopic,
        'player1': user.uid,
        'player1Email': user.email,
        'player2': null,
        'player2Email': null,
        'player1Score': 0,
        'player2Score': 0,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
      });

      roomId = newRoom.id;

      setState(() {
        statusText = '⏳ Chờ đối thủ tham gia...';
      });

      _listenToRoom(newRoom.id);
    }
  }

  /// 🔹 Hủy tìm đối thủ
  Future<void> _cancelSearch() async {
    if (roomId != null) {
      final roomRef = _db.collection('duel_rooms').doc(roomId);
      final doc = await roomRef.get();
      if (doc.exists && doc['status'] == 'waiting') {
        await roomRef.delete();
      }
    }

    setState(() {
      isSearching = false;
      statusText = 'Chọn chủ đề để thi đấu';
      opponentName = null;
      roomId = null;
    });
  }

  /// 🔹 Lắng nghe thay đổi của phòng
  void _listenToRoom(String roomId) {
    _db.collection('duel_rooms').doc(roomId).snapshots().listen((snap) async {
      if (!snap.exists) return;
      final data = snap.data()!;
      final status = data['status'];

      // ✅ Khi vừa match được 2 người
      if (status == 'matched' && !isMatched) {
        setState(() {
          isMatched = true;
          isSearching = false;
        });

        final opponentId =
        data['player1'] == user.uid ? data['player2'] : data['player1'];

        if (opponentId != null) {
          final opponentDoc =
          await _db.collection('users').doc(opponentId).get();
          final opponentData = opponentDoc.data();
          setState(() {
            opponentName = opponentData?['displayName'] ??
                opponentData?['email'] ??
                'Người chơi';
            statusText = '🎯 Đã tìm thấy đối thủ: $opponentName';
          });
        }
      }

      // ✅ Khi cả 2 đã xác nhận, bắt đầu thi đấu
      if (status == 'playing') {
        final topic = data['topic'];
        final questions = topics[topic] ?? [];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(
              topicKey: topic,
              questionList: questions,
            ),
          ),
        ).then((score) async {
          if (score == null) return;
          final field = data['player1'] == user.uid
              ? 'player1Score'
              : 'player2Score';
          await _db.collection('duel_rooms').doc(roomId).update({
            field: score,
          });
        });
      }
    });
  }

  /// 🔹 Xác nhận tham gia trận đấu
  Future<void> _confirmStart() async {
    if (roomId == null) return;
    await _db.collection('duel_rooms').doc(roomId).update({
      'status': 'playing',
    });

    setState(() {
      statusText = '🚀 Trận đấu bắt đầu!';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thi đấu xếp hạng ⚔️'),
        backgroundColor: color.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Chọn chủ đề thi đấu',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              value: selectedTopic,
              items: topics.keys
                  .map((key) => DropdownMenuItem(
                value: key,
                child: Text(key),
              ))
                  .toList(),
              onChanged: (v) => setState(() => selectedTopic = v),
            ),
            const SizedBox(height: 30),

            // 🕹 Nút tìm hoặc hủy
            if (!isSearching && !isMatched)
              ElevatedButton.icon(
                icon: const Icon(Icons.sports_kabaddi),
                label: const Text('Tìm đối thủ'),
                onPressed: _findOpponent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              )
            else if (isSearching)
              OutlinedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Hủy tìm kiếm'),
                onPressed: _cancelSearch,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),

            const SizedBox(height: 40),

            // 🧠 Trạng thái
            Center(
              child: Column(
                children: [
                  if (isSearching) const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    statusText,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // 🎯 Nếu đã tìm thấy đối thủ
                  if (isMatched && opponentName != null)
                    Column(
                      children: [
                        Text(
                          'Đối thủ của bạn là: $opponentName',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Xác nhận tham gia'),
                          onPressed: _confirmStart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
