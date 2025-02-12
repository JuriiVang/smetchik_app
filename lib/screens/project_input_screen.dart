import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectInputScreen extends StatefulWidget {
  final String? projectId; // Если null, значит создаём новый проект

  const ProjectInputScreen({super.key, this.projectId});

  @override
  ProjectInputScreenState createState() => ProjectInputScreenState();
}

class ProjectInputScreenState extends State<ProjectInputScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = "";
  String location = "";
  String description = "";
  String status = "В работе";

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _loadProjectData();
    }
  }

  Future<void> _loadProjectData() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();
      if (doc.exists) {
        var data = doc.data()!;
        setState(() {
          name = data['name'] ?? "";
          location = data['location'] ?? "";
          description = data['description'] ?? "";
          status = data['status'] ?? "В работе";
        });
      }
    } catch (e) {
      debugPrint("Ошибка загрузки проекта: $e");
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    var projectRef = FirebaseFirestore.instance.collection('projects');

    try {
      if (widget.projectId == null) {
        // 📌 Генерируем логичный ID из названия проекта
        String projectId = name.isNotEmpty
            ? name.replaceAll(" ", "_").toLowerCase()
            : "default_project";

        await projectRef.doc(projectId).set({
          'name': name.isNotEmpty ? name : "Без названия",
          'location': location,
          'description': description,
          'status': status,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // ✏ Обновляем существующий проект
        await projectRef.doc(widget.projectId).update({
          'name': name,
          'location': location,
          'description': description,
          'status': status,
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Ошибка сохранения проекта: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ошибка сохранения проекта: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.projectId == null
              ? "Добавить проект"
              : "Редактировать проект")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: name,
                decoration:
                const InputDecoration(labelText: "Название проекта"),
                onChanged: (value) => setState(() => name = value),
                validator: (value) =>
                value!.isEmpty ? "Введите название!" : null,
              ),
              TextFormField(
                initialValue: location,
                decoration: const InputDecoration(labelText: "Расположение"),
                onChanged: (value) => setState(() => location = value),
              ),
              TextFormField(
                initialValue: description,
                decoration: const InputDecoration(labelText: "Описание"),
                onChanged: (value) => setState(() => description = value),
              ),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: "Статус"),
                items: ["В работе", "Завершён", "Заморожен"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => status = value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProject,
                child: Text(widget.projectId == null
                    ? "Добавить проект"
                    : "Сохранить изменения"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
