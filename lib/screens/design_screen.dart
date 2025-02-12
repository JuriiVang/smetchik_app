import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'secrets.dart'; // Файл с API-ключом
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_image/flutter_image.dart'; // 📌 Импортируем пакет

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
  String selectedStyle = "Современный";
  String selectedBudget = "Стандарт";
  String designDescription = "Нажмите 'Создать проект', чтобы получить описание";
  String? imageUrl; // 🔹 Для хранения ссылки на изображение

  Future<void> _generateDesign() async {
    debugPrint("📢 Начинаем генерацию проекта...");
    debugPrint("➡ Стиль: $selectedStyle, Бюджет: $selectedBudget");

    try {
      // 🔹 Генерация текстового описания
      String result = await generateDesign("комната", selectedStyle, selectedBudget);

      // 🔹 Генерация изображения
      String image = await generateImage(selectedStyle);

      setState(() {
        designDescription = result;
        imageUrl = image;
      });
    } catch (e) {
      debugPrint("❌ Ошибка при генерации проекта: $e");
      setState(() {
        designDescription = "Ошибка при генерации проекта.";
        imageUrl = null; // Обнуляем изображение, если ошибка
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
            const Text("Выберите стиль:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            DropdownButtonFormField<String>(
              value: ["Современный", "Классика", "Минимализм", "Стандарт"].contains(selectedStyle)
                  ? selectedStyle
                  : "Современный",
              decoration: const InputDecoration(labelText: "Стиль"),
              items: ["Современный", "Классика", "Минимализм", "Стандарт"]
                  .map((style) => DropdownMenuItem(value: style, child: Text(style)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedStyle = value!;
                });
              },
            ),

            const SizedBox(height: 10),

            const Text("Выберите бюджет:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedBudget,
              items: ["Эконом", "Стандарт", "Премиум"].map((String budget) {
                return DropdownMenuItem(value: budget, child: Text(budget));
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedBudget = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _generateDesign,
              child: const Text("Создать проект"),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: designDescription,
                ),
              ),
            ),



               Image.network(
                 imageUrl,
                 loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator()); // 🔄 Показываем загрузку
                 },
                 errorBuilder: (context, error, stackTrace) {
                   return const Icon(Icons.error, size: 50, color: Colors.red); // ❌ Ошибка загрузки
                 },
               )

          ],
        ),
      ),
    );
  }
}

// ✅ **Функция генерации дизайна (ОСТАЕТСЯ ПРЕЖНЕЙ)**
Future<String> generateDesign(String roomType, String style, String budget) async {
  const apiUrl = "https://api.openai.com/v1/chat/completions";

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Authorization": "Bearer $openAiApiKey", // 🔑 Используем ключ
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-4o",
        "messages": [
          {"role": "system", "content": "Ты профессиональный дизайнер интерьеров."},
          {"role": "user", "content": "Создай проект для $roomType в стиле $style с бюджетом $budget."}
        ],
        "max_tokens": 1000
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data["choices"][0]["message"]["content"];
    } else {
      throw Exception("Ошибка OpenAI: ${response.body}");
    }
  } catch (e) {
    return "Ошибка при запросе OpenAI: $e";
  }
}

// ✅ **Функция генерации изображения через DALL·E 3**
Future<String> generateImage(String style) async {
  const String apiUrl = "https://api.openai.com/v1/images/generations";

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Authorization": "Bearer $openAiApiKey", // 🔑 Используем тот же API-ключ
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "dall-e-3",
        "prompt": "Beautiful interior design in $style style",
        "n": 1,
        "size": "1024x1024",
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["data"][0]["url"];
    } else {
      throw Exception("Ошибка генерации изображения: ${response.body}");
    }
  } catch (e) {
    return "Ошибка при запросе изображения: $e";
  }
}
