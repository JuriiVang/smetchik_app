import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'building_input_screen.dart'; // 🏗 Экран ввода здания
import 'room_list_screen.dart'; // 🚪 Экран списка комнат

class BuildingListScreen extends StatelessWidget {
  final String projectId;

  const BuildingListScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Список зданий")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('buildings')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var buildings = snapshot.data!.docs;

          return ListView.builder(
            itemCount: buildings.length,
            itemBuilder: (context, index) {
              var building = buildings[index];
              var buildingData =
              building.data() as Map<String, dynamic>?; // ✅ Исправлено

              // ✅ Добавляем защиту от отсутствующих данных
              String name = buildingData?['name'] ?? "Без названия";
              int floors = (buildingData?['floors'] ?? 1).toInt();

              return ListTile(
                title: Text(name),
                subtitle: Text("Этажей: $floors"),
                onTap: () {
                  if (!context.mounted) return; // ✅ Проверяем, что экран активен
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomListScreen(
                        projectId: projectId,
                        buildingId: building.id,
                      ),
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BuildingInputScreen(
                              projectId: projectId,
                              buildingId: building.id,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('projects')
                              .doc(projectId)
                              .collection('buildings')
                              .doc(building.id)
                              .delete();
                          debugPrint("✅ Здание удалено: $name");
                        } catch (e) {
                          debugPrint("❌ Ошибка удаления здания: $e");
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Ошибка удаления здания: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BuildingInputScreen(projectId: projectId, buildingId: null),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
