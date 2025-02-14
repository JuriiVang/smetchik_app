import 'dart:convert';
import 'package:http/http.dart' as http;
import '../secrets.dart'; // Файл с API-ключом

class OpenAIService {
  // 🔍 Анализ чертежа
  static Future<String> analyzeDrawing(String imageBase64) async {
    const String apiUrl = "https://api.openai.com/v1/chat/completions";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $openAiApiKey",
          "Content-Type": "application/json",
          "OpenAI-Beta": "assistants=v2"
        },
        body: jsonEncode({
          "model": "gpt-4o",
          "messages": [
            {"role": "system", "content": "Ты строительный эксперт, анализируешь чертежи."},
            {"role": "user", "content": "Проанализируй этот чертеж и извлеки размеры."}
          ],
          "max_tokens": 300
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];
      } else {
        throw Exception("Ошибка OpenAI: ${response.body}");
      }
    } catch (e) {
      return "Ошибка при анализе чертежа: $e";
    }
  }

  // 📐 Анализ параметров комнаты
  static Future<String> analyzeRoom(String assistantId, Map<String, dynamic> roomData) async {
    const String apiUrl = "https://api.openai.com/v1/chat/completions";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $openAiApiKey",
          "Content-Type": "application/json",
          "OpenAI-Beta": "assistants=v2"
        },
        body: jsonEncode({
          "model": "gpt-4o",
          "messages": [
            {"role": "system", "content": "Ты строительный эксперт, анализируешь размеры помещений."},
            {"role": "user", "content": "Проанализируй комнату с такими параметрами: $roomData"}
          ],
          "max_tokens": 300
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];
      } else {
        throw Exception("Ошибка OpenAI: ${response.body}");
      }
    } catch (e) {
      return "Ошибка при анализе комнаты: $e";
    }
  }
}
