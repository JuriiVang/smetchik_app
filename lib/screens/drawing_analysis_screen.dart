import 'package:flutter/material.dart';
import '../services/openai_service.dart';

class DrawingAnalysisScreen extends StatefulWidget {
  final String projectId;
  final String buildingId;
  final String roomId;

  const DrawingAnalysisScreen({
    super.key,
    required this.projectId,
    required this.buildingId,
    required this.roomId,
  });

  @override
  State<DrawingAnalysisScreen> createState() => _DrawingAnalysisScreenState();
}

class _DrawingAnalysisScreenState extends State<DrawingAnalysisScreen> {
  String _analysisResult = "Введите запрос для анализа.";

  Future<void> _analyzeRoom() async {
    setState(() => _analysisResult = "🔄 Анализируем...");

    try {
      String response = await OpenAIService.analyzeRoom(
          widget.projectId,   // ✅ projectId
          widget.buildingId,  // ✅ buildingId
          "roomId_placeholder", // ✅ Если нет roomId, подставляем "default_room"
          "Проанализируй данные этой комнаты и дай рекомендации."


    );

      setState(() => _analysisResult = response);
    } catch (e) {
      setState(() => _analysisResult = "❌ Ошибка: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📐 Анализ помещения")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _analyzeRoom,
              child: const Text("🔍 Анализировать"),
            ),
            const SizedBox(height: 20),
            Text(_analysisResult, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
