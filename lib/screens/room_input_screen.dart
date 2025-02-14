import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // ✅ Кодирование Base64
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/openai_service.dart';
import '../services/firebase_service.dart';
import 'design_screen.dart';

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
  File? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) {
      _loadRoomData();
    }
  }

  Future<void> _loadRoomData() async {
    try {
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
        });
      }
    } catch (e) {
      debugPrint("❌ Ошибка загрузки комнаты: $e");
    }
  }

  Future<void> _saveRoomData() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String roomId = widget.roomId ?? roomNameController.text.toLowerCase().replaceAll(" ", "_");

      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('buildings')
          .doc(widget.buildingId)
          .collection('rooms')
          .doc(roomId)
          .set({
        'name': roomNameController.text,
        'width': double.tryParse(widthController.text) ?? 0.0,
        'length': double.tryParse(lengthController.text) ?? 0.0,
        'height': double.tryParse(heightController.text) ?? 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Комната сохранена!')));
      Navigator.pop(context);
    } catch (e) {
      debugPrint("❌ Ошибка сохранения комнаты: $e");
    }
  }

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
        widget.roomId!,
        dimensions,
      );

      setState(() {
        widthController.text = dimensions['width'].toString();
        lengthController.text = dimensions['length'].toString();
        heightController.text = dimensions['height'].toString();
      });
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
      appBar: AppBar(title: const Text("Ввод размеров")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(controller: roomNameController, decoration: const InputDecoration(labelText: "Название")),
                TextFormField(controller: widthController, decoration: const InputDecoration(labelText: "Ширина (м)"), keyboardType: TextInputType.number),
                TextFormField(controller: lengthController, decoration: const InputDecoration(labelText: "Длина (м)"), keyboardType: TextInputType.number),
                TextFormField(controller: heightController, decoration: const InputDecoration(labelText: "Высота (м)"), keyboardType: TextInputType.number),

                const SizedBox(height: 20),
                ElevatedButton(onPressed: _saveRoomData, child: const Text("Сохранить")),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: _pickImage, child: const Text("Загрузить чертеж")),
                ElevatedButton(onPressed: _analyzeDrawing, child: const Text("🔍 Анализировать")),
                if (_isLoading) const CircularProgressIndicator(),
                if (_image != null) Image.file(_image!, height: 200),

                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (widget.roomId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("⚠️ Сначала сохраните комнату!"),
                        backgroundColor: Colors.orange,
                      ));
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DesignScreen(
                      projectId: widget.projectId,
                      buildingId: widget.buildingId,
                      roomId: widget.roomId!,
                    )));
                  },
                  child: const Text("Проектировать"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
