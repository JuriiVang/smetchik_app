import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_input_screen.dart'; // Экран для добавления/редактирования комнат

class RoomListScreen extends StatelessWidget {
  final String projectId;
  final String buildingId;

  const RoomListScreen({
    super.key,
    required this.projectId,
    required this.buildingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📋 Список комнат")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('buildings')
            .doc(buildingId)
            .collection('rooms')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("❌ Нет комнат"));
          }

          var rooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              var room = rooms[index];
              var roomData = room.data() as Map<String, dynamic>? ?? {};

              String roomName = roomData['name'] ?? 'Без названия';
              double roomLength =
                  (roomData['length'] ?? 0.0).toDouble(); // ✅ Защита от `null`

              return ListTile(
                title: Text(roomName),
                subtitle: Text("Площадь: $roomLength м²"),
                onTap: () {
                  // 🔥 Открываем экран редактирования комнаты
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomInputScreen(
                        projectId: projectId,
                        buildingId: buildingId,
                        roomId: room.id,
                      ),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('projects')
                        .doc(projectId)
                        .collection('buildings')
                        .doc(buildingId)
                        .collection('rooms')
                        .doc(room.id)
                        .delete();

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Комната удалена")),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 🔥 Добавляем новую комнату
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomInputScreen(
                projectId: projectId,
                buildingId: buildingId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
