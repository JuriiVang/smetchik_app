import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DesignScreen extends StatefulWidget {
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

class _DesignScreenState extends State<DesignScreen> {
String designDescription = "⏳ Анализ комнаты не выполнен.";

@override
void initState() {
super.initState();
_analyzeRoom(); // Запуск анализа при загрузке экрана
}

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

if (!roomSnapshot.exists || roomSnapshot.data() == null) {
if (mounted) {
setState(() {
designDescription = "❌ Ошибка: Данные комнаты не найдены!";
});
}
return;
}

Map<String, dynamic> roomData = roomSnapshot.data() ?? {};

// ❗ Здесь можно добавить запрос к OpenAI или локальную обработку roomData
String analysisResult = "📊 Анализ комнаты:\n"
"- Ширина: ${roomData['width']} м\n"
"- Длина: ${roomData['length']} м\n"
"- Высота: ${roomData['height']} м\n"
"🔹 Комната имеет прямоугольную форму.";
if (widget.roomId.isEmpty) {
setState(() {
designDescription = "❌ Ошибка: ID комнаты отсутствует!";
});
return;
}

if (mounted) {
setState(() {
designDescription = analysisResult;
});
}
} catch (e) {
if (mounted) {
setState(() {
designDescription = "❌ Ошибка при анализе: $e";
});
}
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text("Проектирование")),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
ElevatedButton.icon(
onPressed: _analyzeRoom,
icon: const Icon(Icons.search),
label: const Text("🔍 Анализировать комнату"),
),
const SizedBox(height: 20),
Text(
designDescription,
style: const TextStyle(fontSize: 16),
),
],
),
),
),
);
}
}