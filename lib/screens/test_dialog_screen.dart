import 'package:flutter/material.dart';
import '../services/openai_service.dart';
import '../secrets.dart'; // ✅ Добавляем импорт


class TestDialogScreen extends StatefulWidget {
  final String projectId;
  final String buildingId;
  final String roomId;

  const TestDialogScreen({
    super.key,
    required this.projectId,
    required this.buildingId,
    required this.roomId,
  });

  @override
  _TestDialogScreenState createState() => _TestDialogScreenState();
}

class _TestDialogScreenState extends State<TestDialogScreen> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  bool isPolygon = false;
  List<Map<String, String>> messages = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({"role": "user", "content": text});
      isLoading = true;
    });

    String response = await OpenAIService.analyzeRoom(
      widget.projectId,
      widget.buildingId,
      widget.roomId,
      text,
    );

    setState(() {
      messages.add({"role": "assistant", "content": response});
      isLoading = false;
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Анализ комнаты")),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text("Нестандартная форма"),
            value: isPolygon,
            onChanged: (value) {
              setState(() {
                isPolygon = value;
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]["content"] ?? ""),
                  tileColor: messages[index]["role"] == "user"
                      ? Colors.blue[50]
                      : Colors.green[50],
                );
              },
            ),
          ),
          if (isLoading) const CircularProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Введите сообщение..."),
                    onSubmitted: sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
