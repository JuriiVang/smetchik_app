import 'dart:convert';
import 'package:http/http.dart' as http;
import '../secrets.dart'; // API-ключ OpenAI

class OpenAIAssistant {
  // 📌 Анализ чертежа через OpenAI Vision
  static Future<String> analyzeDrawing(String base64Image) async {
    const String apiUrl = "https://api.openai.com/v1/chat/completions";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $openAiApiKey", // 🔑 API-ключ
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-4-vision-preview", // 🔍 Используем модель Vision
          "messages": [
            {
              "role": "system",
              "content": "Ты инженер-строитель. Анализируй чертежи, считывай размеры и создавай расчеты."
            },
            {
              "role": "user",
              "content": [

            {
                  "type": "text",
                  "text": "Проанализируй чертеж и определи размеры помещения, стены и двери."
                },
            {
              "type": "image_url",
              "image_url": {"url": "data:image/png;base64,$base64Image"}
            }
               ]
            }
          ],
          "max_tokens": 500
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data["choices"][0]["message"]["content"];
      } else {
        throw Exception("Ошибка OpenAI: ${response.body}");
      }
    } catch (e) {
      return "Ошибка при анализе чертежа: $e";
    }
  }
}
