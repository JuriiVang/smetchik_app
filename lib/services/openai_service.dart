import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../secrets.dart'; // API-ключи

class OpenAIService {
  // ✅ 1. Простой чат с ассистентом (1 аргумент)
  static Future<String> askAssistant(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $openAiApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",

          "messages": [
            {"role": "system", "content": "Ты строительный ассистент."},
            {"role": "user", "content": userMessage}
          ],
          "max_tokens": 500,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        return data["choices"][0]["message"]["content"] ?? "Ошибка обработки ответа";
      } else {
        return "Ошибка запроса: ${response.statusCode}, ${response.body}";
      }
    } catch (e) {
      return "Ошибка сети: $e";
    }
  }

  // ✅ 2. Анализ комнаты (4 аргумента)
  static Future<String> analyzeRoom(
      String projectId,
      String buildingId,
      String roomId,
      String userMessage,
      ) async {
    try {
      var roomSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('buildings')
          .doc(buildingId)
          .collection('rooms')
          .doc(roomId)
          .get();

      if (!roomSnapshot.exists) {
        return "⚠ Ошибка: Данные комнаты не найдены!";
      }

      var roomData = roomSnapshot.data();

      Map<String, dynamic> requestData = {
        "room": {
          "name": roomData?['name'] ?? "Без названия",
          "width": roomData?['width'] ?? 0,
          "length": roomData?['length'] ?? 0,
          "height": roomData?['height'] ?? 0,
          "additionalSizes": roomData?['additionalSizes'] ?? [],
        },
        "query": userMessage
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $openAiApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",

          "messages": [
            {"role": "system", "content": "Ты строительный ассистент, используй размеры комнаты для расчетов."},
            {"role": "user", "content": jsonEncode(requestData)}
          ],
          "max_tokens": 500,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        return data["choices"][0]["message"]["content"] ?? "Ошибка обработки ответа";
      } else {
        return "Ошибка запроса: ${response.statusCode}, ${response.body}";
      }
    } catch (e) {
      return "Ошибка сети: $e";
    }
  }
}
