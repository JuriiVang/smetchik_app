import 'package:flutter/material.dart';
import '../services/openai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_input_screen.dart';
import 'design_screen.dart';
import 'test_dialog_screen.dart';  // ✅ Добавляем импорт
import '../secrets.dart'; // ✅ Добавляем импорт


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
      appBar: AppBar(title: const Text("Список комнат")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('buildings')
            .doc(buildingId)
            .collection('rooms')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var rooms = snapshot.data!.docs;
          print("🚀 Загруженные комнаты: ${rooms.length}");

          return ListView.builder(
            itemCount: rooms.length,

            itemBuilder: (context, index) {

              var room = rooms[index];
              var roomData = room.data() as Map<String, dynamic>?;
              print("🛠 Обрабатываем комнату: ${room.id}");

              String name = roomData?['name'] ?? "Без названия";

              return ListTile(
                title: Text(name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DesignScreen(
                        projectId: projectId,
                        buildingId: buildingId,
                        roomId: room.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("📌 Открываем RoomInputScreen");
          print("➡ projectId: $projectId");
          print("➡ buildingId: $buildingId");
          print("➡ roomId: null (создаём новую комнату)");

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomInputScreen(
                projectId: projectId,
                buildingId: buildingId,
                roomId: null, // ✅ Для новой комнаты roomId должен быть null
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
