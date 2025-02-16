import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/openai_service.dart';
import '../services/firebase_service.dart';

class RoomInputScreen extends StatefulWidget {
  final String projectId;
  final String buildingId;
  final String? roomId;

  const RoomInputScreen({
    super.key,
    required this.projectId,
    required this.buildingId,
    this.roomId,
  });

  @override
  RoomInputScreenState createState() => RoomInputScreenState();
}

class RoomInputScreenState extends State<RoomInputScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController roomNameController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  List<Map<String, dynamic>> additionalSizes = [];

  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) {
      _loadRoomData();
      print("✅ projectId: ${widget.projectId}");
      print("✅ buildingId: ${widget.buildingId}");
      print("✅ roomId: ${widget.roomId}");
    }
  }

  Future<void> _loadRoomData() async {
    var roomSnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('buildings')
        .doc(widget.buildingId)
        .collection('rooms')
        .doc(widget.roomId)
        .get();

    if (roomSnapshot.exists) {
      var data = roomSnapshot.data()!;
      setState(() {
        roomNameController.text = data['name'] ?? '';
        widthController.text = data['width']?.toString() ?? '';
        lengthController.text = data['length']?.toString() ?? '';
        heightController.text = data['height']?.toString() ?? '';
        additionalSizes = List<Map<String, dynamic>>.from(data['additionalSizes'] ?? []);
      });
    }
  }

  Future<void> _saveRoomData() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('buildings')
        .doc(widget.buildingId)
        .collection('rooms')
        .doc(widget.roomId ?? roomNameController.text.toLowerCase().replaceAll(" ", "_"))
        .set({
      'name': roomNameController.text,
      'width': double.tryParse(widthController.text) ?? 0.0,
      'length': double.tryParse(lengthController.text) ?? 0.0,
      'height': double.tryParse(heightController.text) ?? 0.0,
      'additionalSizes': additionalSizes,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Комната сохранена!')));
  }

  void _showAssistantDialog(BuildContext context) {
    TextEditingController _queryController = TextEditingController();
    String _assistantResponse = "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🤖 Помощник проектирования"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _queryController,
                decoration: const InputDecoration(hintText: "Введите ваш запрос"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  if (_queryController.text.isNotEmpty) {
                    if (_queryController.text.isEmpty) {
                      print("🚨 Ошибка: пустой запрос!");
                      return;
                    }
                    if (widget.roomId == null) {
                      print("⚠ Внимание: roomId == null, подставляем 'room_placeholder_id'.");
                    }
                    if (widget.projectId == null || widget.buildingId == null) {
                      print("🚨 Ошибка: projectId или buildingId == null!");
                      return;
                    }

                    String response = await OpenAIService.analyzeRoom(
                      widget.projectId,  // ✅ ID проекта
                      widget.buildingId, // ✅ ID здания
                        widget.roomId ?? "room_placeholder_id",
                        _queryController.text,  // ✅ Используем ввод пользователя
                            //"asst_Dlvf13Qkrd7r18nRchyshQvs"

                    );
                    setState(() => _assistantResponse = response);
                  }
                },
                child: const Text("🔍 Запросить"),
              ),
              const SizedBox(height: 10),
              Text(_assistantResponse),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Закрыть"),
          ),
        ],
      ),
    );
  }

  void _addAdditionalSize() {
    setState(() {
      additionalSizes.add({"name": "", "width": "", "height": "", "depth": ""});
    });
  }

  void _removeAdditionalSize(int index) {
    setState(() {
      additionalSizes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Редактирование комнаты")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAssistantDialog(context),
        child: const Icon(Icons.chat),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(controller: roomNameController, decoration: const InputDecoration(labelText: "Название")),
                TextFormField(controller: widthController, decoration: const InputDecoration(labelText: "Ширина (м)"), keyboardType: TextInputType.number),
                TextFormField(controller: lengthController, decoration: const InputDecoration(labelText: "Длина (м)"), keyboardType: TextInputType.number),
                TextFormField(controller: heightController, decoration: const InputDecoration(labelText: "Высота (м)"), keyboardType: TextInputType.number),

                const SizedBox(height: 20),
                const Text("Дополнительные размеры", style: TextStyle(fontWeight: FontWeight.bold)),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: additionalSizes.length,
                  itemBuilder: (context, index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Название (дверь, окно и т. д.)"),
                          initialValue: additionalSizes[index]["name"],
                          onChanged: (value) => additionalSizes[index]["name"] = value,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Ширина (м)"),
                          keyboardType: TextInputType.number,
                          initialValue: additionalSizes[index]["width"],
                          onChanged: (value) => additionalSizes[index]["width"] = value,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Высота (м)"),
                          keyboardType: TextInputType.number,
                          initialValue: additionalSizes[index]["height"],
                          onChanged: (value) => additionalSizes[index]["height"] = value,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Глубина (м)"),
                          keyboardType: TextInputType.number,
                          initialValue: additionalSizes[index]["depth"],
                          onChanged: (value) => additionalSizes[index]["depth"] = value,
                        ),
                        TextButton(
                          onPressed: () => _removeAdditionalSize(index),
                          child: const Text("Удалить"),
                        ),
                        const Divider(),
                      ],
                    );
                  },
                ),

                ElevatedButton(
                  onPressed: _addAdditionalSize,
                  child: const Text("➕ Добавить размер"),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _showAssistantDialog(context),
                  child: const Text("🤖 Вызвать ассистента"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    String response = await OpenAIService.analyzeRoom(
                      widget.projectId,
                      widget.buildingId,
                      widget.roomId!,
                      "asst_Dlvf13Qkrd7r18nRchyshQvs", // ✅ Добавляем ID ассистента
                    );

                    // Показываем результат анализа
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response)),
                    );
                  },
                  child: const Text("🔍 Анализировать комнату"),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (widget.roomId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("⚠ Сначала сохраните комнату!")),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomInputScreen(
                          projectId: widget.projectId,
                          buildingId: widget.buildingId,
                          roomId: widget.roomId!,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text("✏ Редактировать комнату"),
                ),


                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveRoomData,
                  child: const Text("💾 Сохранить"),



                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
