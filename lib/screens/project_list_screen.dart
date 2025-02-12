import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'building_list_screen.dart';
import 'project_input_screen.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📂 Список проектов")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('projects').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Ошибка загрузки данных: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var projects = snapshot.data!.docs;

          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              var project = projects[index];
              var projectData = project.data() as Map<String, dynamic>?;

              // ✅ Проверяем, что поле существует в Firestore
              String projectName = projectData?['name'] ?? 'Без названия';
              String projectLocation = projectData?['location'] ?? 'Нет данных';

              return ListTile(
                title: Text(projectName),
                subtitle: Text(projectLocation),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('projects')
                          .doc(project.id)
                          .delete();

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Проект удалён!")),
                      );
                    } catch (e) {
                      debugPrint("Ошибка при удалении проекта: $e");

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Ошибка удаления: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                onTap: () {
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BuildingListScreen(projectId: project.id),
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
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProjectInputScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
