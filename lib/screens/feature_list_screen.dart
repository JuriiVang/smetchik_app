import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'feature_input_screen.dart';

class FeatureListScreen extends StatelessWidget {
  final String projectId;
  final String buildingId;
  final String roomId;

  const FeatureListScreen({
    super.key,
    required this.projectId,
    required this.buildingId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Окна и двери")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('buildings')
            .doc(buildingId)
            .collection('rooms')
            .doc(roomId)
            .collection('features')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Ошибка загрузки данных: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var features = snapshot.data!.docs;

          return ListView.builder(
            itemCount: features.length,
            itemBuilder: (context, index) {
              var feature = features[index];
              var featureData =
                  feature.data() as Map<String, dynamic>?; // ✅ Исправлено

              // ✅ Добавляем защиту от отсутствующих данных
              String type = featureData?['type'] ?? "Неизвестно";
              double width = (featureData?['width'] ?? 0.0).toDouble();
              double height = (featureData?['height'] ?? 0.0).toDouble();

              return ListTile(
                title: Text("$type: $widthм × $heightм"),
                onTap: () {
                  debugPrint("Открываем featureId: ${feature.id}");

                  if (!context.mounted){
                    return; // ✅ Проверяем, что экран смонтирован
                     }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FeatureInputScreen(
                        projectId: projectId,
                        buildingId: buildingId,
                        roomId: roomId,
                        featureId: feature.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
