import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuildingInputScreen extends StatefulWidget {
  final String projectId;
  final String? buildingId; // Если null, создаём новое здание

  const BuildingInputScreen({
    super.key,
    required this.projectId,
    this.buildingId,
  });

  @override
  BuildingInputScreenState createState() => BuildingInputScreenState();
}

class BuildingInputScreenState extends State<BuildingInputScreen> {
  final _formKey = GlobalKey<FormState>();
  String buildingName = "";
  int floors = 1;

  @override
  void initState() {
    super.initState();
    if (widget.buildingId != null) {
      _loadBuildingData();
    }
  }

  Future<void> _loadBuildingData() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('buildings')
          .doc(widget.buildingId)
          .get();

      if (doc.exists) {
        var data = doc.data()!;
        setState(() {
          buildingName = data['name'] ?? "";
          floors = data['floors'] ?? 1; // ✅ Добавили загрузку этажей
        });
      }
    } catch (e) {
      debugPrint("Ошибка загрузки здания: $e");
    }
  }

  Future<void> _saveBuilding() async {
    if (!_formKey.currentState!.validate()) return;

    var buildingRef = FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('buildings');

    try {
      if (widget.buildingId == null) {
        // 🏗 Генерируем ID из названия (если название пустое - используем `default_building`)
        String buildingId = (buildingName.isNotEmpty ? buildingName : "default_building")
            .replaceAll(" ", "_")
            .toLowerCase();

        debugPrint("Сохраняем здание с ID: $buildingId"); // 🔥 Проверка в консоли

        await buildingRef.doc(buildingId).set({
          'name': buildingName.isNotEmpty ? buildingName : "Без названия",
          'floors': floors,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // ✏ Обновляем существующее здание
        await buildingRef.doc(widget.buildingId).update({
          'name': buildingName,
          'floors': floors,
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Ошибка сохранения здания: $e"); // 🔥 Логируем ошибку
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.buildingId == null
            ? "Добавить здание"
            : "Редактировать здание"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: buildingName,
                decoration: const InputDecoration(labelText: "Название здания"),
                onChanged: (value) => buildingName = value,
                validator: (value) =>
                value!.isEmpty ? "Введите название!" : null,
              ),
              TextFormField(
                initialValue: floors.toString(),
                decoration:
                const InputDecoration(labelText: "Количество этажей"),
                keyboardType: TextInputType.number,
                onChanged: (value) => floors = int.tryParse(value) ?? 1,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveBuilding,
                child: Text(widget.buildingId == null
                    ? "Добавить здание"
                    : "Сохранить изменения"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
