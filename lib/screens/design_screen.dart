import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/openai_service.dart';
class DesignScreen extends StatefulWidget {  // ✅ Должно быть StatefulWidget
  final String projectId;
  final String buildingId;
  final String roomId;

  const DesignScreen({
    super.key,
    required this.projectId,
    required this.buildingId,
    required this.roomId,
  });

  @override
  State<DesignScreen> createState() => _DesignScreenState();
}

class _DesignScreenState extends State<DesignScreen> {  // ✅ Теперь 'widget' доступен
  String designDescription = "Анализ комнаты не выполнен";

  Future<void> _analyzeRoom() async {
    try {
      var roomSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('buildings')
          .doc(widget.buildingId)
          .collection('rooms')
          .doc(widget.roomId)
          .get();

      if (!roomSnapshot.exists) {
        setState(() {
          designDescription = "❌ Ошибка: Данные комнаты не найдены!";
        });
        return;
      }

      Map<String, dynamic> roomData = roomSnapshot.data()!;
      String analysisResult = await OpenAIService.analyzeRoom("asst_Dlvf13Qkrd7r18nRchyshQvs", roomData);

      setState(() {
        designDescription = analysisResult;
      });
    } catch (e) {
      debugPrint("❌ Ошибка при анализе комнаты: $e");
      setState(() {
        designDescription = "Ошибка при анализе проекта.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Проектирование")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _analyzeRoom,
              child: const Text("🔍 Анализировать комнату"),
            ),
            const SizedBox(height: 20),
            Text(
              designDescription,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}