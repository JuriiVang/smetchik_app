import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeatureInputScreen extends StatefulWidget {
  final String projectId;
  final String buildingId;
  final String roomId;
  final String? featureId; // null - создание нового объекта

  const FeatureInputScreen({
    super.key,
    required this.projectId,
    required this.buildingId,
    required this.roomId,
    this.featureId,
  });

  @override
  State<FeatureInputScreen> createState() => _FeatureInputScreenState();
}

class _FeatureInputScreenState extends State<FeatureInputScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController widthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController depthController = TextEditingController();
  final TextEditingController materialController = TextEditingController();

  String featureType = "Окно"; // По умолчанию
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.featureId != null) {
      isEditing = true;
      _loadFeatureData();
    }
  }

  @override
  void dispose() {
    widthController.dispose();
    heightController.dispose();
    depthController.dispose();
    materialController.dispose();
    super.dispose();
  }

  Future<void> _loadFeatureData() async {
    debugPrint("🔄 Загружаем объект: ${widget.featureId}");

    try {
      var featureDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('buildings')
          .doc(widget.buildingId)
          .collection('rooms')
          .doc(widget.roomId)
          .collection('features')
          .doc(widget.featureId)
          .get();

      if (featureDoc.exists) {

        var data = featureDoc.data()!;
        setState(() {
          featureType = data['type'] ?? "Окно";
          widthController.text = data['width']?.toString() ?? "";
          heightController.text = data['height']?.toString() ?? "";
          depthController.text = data['depth']?.toString() ?? "";
          materialController.text = data['material'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Ошибка загрузки объекта: $e");
    }
  }

  Future<void> _saveFeatureData() async {
    if (!_formKey.currentState!.validate()) return;


    debugPrint("📌 Сохраняем объект: type=$featureType, width=${widthController.text}");

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('buildings')
        .doc(widget.buildingId)
        .collection('rooms')
        .doc(widget.roomId)
        .collection('features')
        .doc('featureId')
        .set({
      'type': featureType,
      'width': double.tryParse(widthController.text) ?? 0.0,
      'height': double.tryParse(heightController.text) ?? 0.0,
      'depth': double.tryParse(depthController.text) ?? 0.0,
      'material': materialController.text.isNotEmpty ? materialController.text : "Не указано",
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$featureType добавлено!"), backgroundColor: Colors.green),
    );
    debugPrint("✅ Завершаем работу с объектом: $featureType");

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Редактировать объект" : "Добавить объект")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: featureType,
                decoration: const InputDecoration(labelText: "Тип объекта"),
                items: ["Окно", "Дверь", "Другое"]
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    featureType = value!;
                  });
                },
              ),
              TextField(
                controller: widthController,
                decoration: const InputDecoration(labelText: "Ширина (м)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: heightController,
                decoration: const InputDecoration(labelText: "Высота (м)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: depthController,
                decoration: const InputDecoration(labelText: "Глубина (м)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: materialController,
                decoration: const InputDecoration(labelText: "Материал"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveFeatureData,
                child: Text(isEditing ? "Сохранить изменения" : "Добавить объект"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
