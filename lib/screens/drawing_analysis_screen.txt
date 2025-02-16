import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // ✅ Добавляем кодирование Base64
import '../services/openai_service.dart';
import '../services/firebase_service.dart';

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
  File? _image;
  bool _isLoading = false;
  Map<String, dynamic>? roomDimensions;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _analyzeDrawing() async {
    if (_image == null) return;

    setState(() => _isLoading = true);

    try {
      // ✅ Кодируем изображение в Base64
      List<int> imageBytes = await _image!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // ✅ Отправляем на анализ
      String responseText = await OpenAIService.analyzeDrawing(base64Image);
      debugPrint("📝 Ответ от AI: $responseText");

      // ✅ Парсим размеры
      Map<String, dynamic> dimensions = _parseDimensions(responseText);
      debugPrint("📐 Извлечённые размеры: $dimensions");

      // ✅ Сохраняем в Firestore
      await FirebaseService.saveRoomDimensions(
        widget.projectId,
        widget.buildingId,
        widget.roomId,
        dimensions,
      );

      setState(() => roomDimensions = dimensions);
    } catch (e) {
      debugPrint("❌ Ошибка при анализе чертежа: $e");
    }

    setState(() => _isLoading = false);
  }

  // 🔍 Парсим размеры из текста OpenAI
  Map<String, dynamic> _parseDimensions(String text) {
    final Map<String, dynamic> dimensions = {};
    final RegExp regex = RegExp(r'(\w+):\s*([\d.]+)\s*м');

    for (final match in regex.allMatches(text)) {
      dimensions[match.group(1)!] = double.tryParse(match.group(2)!) ?? 0.0;
    }

    return dimensions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📐 Анализ чертежа")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _image != null
                ? Image.file(_image!, height: 200)
                : const Text("Выберите изображение"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("📤 Выбрать чертеж"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _analyzeDrawing,
              child: const Text("🔍 Анализировать"),
            ),
            if (_isLoading) const CircularProgressIndicator(),
            if (roomDimensions != null) ...[
              const SizedBox(height: 20),
              const Text("📊 **Результаты анализа:**"),
              Text("Ширина: ${roomDimensions!['width']} м"),
              Text("Длина: ${roomDimensions!['length']} м"),
              Text("Высота: ${roomDimensions!['height']} м"),
              Text("Площадь: ${roomDimensions!['area']} м²"),
              Text("Объем: ${roomDimensions!['volume']} м³"),
            ],
          ],
        ),
      ),
    );
  }
}
