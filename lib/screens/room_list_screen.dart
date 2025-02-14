import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_input_screen.dart'; // ✅ Экран ввода комнаты
import 'design_screen.dart'; // ✅ Экран проектирования

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

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              var room = rooms[index];
              var roomData = room.data() as Map<String, dynamic>?;

              String name = roomData?['name'] ?? "Без названия";

              return ListTile(
                title: Text(name),
                onTap: () {
                  print("🟢 Открываем комнату: ${room.id}"); // ✅ Проверяем ID комнаты
                  print("📌 Проект: $projectId, Здание: $buildingId, Комната: ${room.id}");

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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomInputScreen(
                projectId: projectId,
                buildingId: buildingId,
                roomId: null,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
