import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'feature_list_screen.dart'; // Экран для списка объектов (окон, дверей)
import 'package:smetchikapp/screens/design_screen.dart';

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
  final TextEditingController heightController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController windowsController = TextEditingController();

  bool hasWindows = false;
  String? selectedMaterial;

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
        var roomData = roomSnapshot.data()!;
        setState(() {
          roomNameController.text = roomData['name'] ?? '';
          heightController.text = (roomData['height'] ?? 0).toString();
          widthController.text = (roomData['width'] ?? 0).toString();
          lengthController.text = (roomData['length'] ?? 0).toString();
          windowsController.text = (roomData['windowsCount'] ?? 0).toString();
          selectedMaterial = roomData['material'] ?? "Не указано";
          hasWindows = roomData['hasWindows'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Ошибка загрузки комнаты: $e");
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
        'name': roomNameController.text.isNotEmpty ? roomNameController.text : 'Без названия',
        'height': double.tryParse(heightController.text) ?? 0.0,
        'width': double.tryParse(widthController.text) ?? 0.0,
        'length': double.tryParse(lengthController.text) ?? 0.0,
        'windowsCount': int.tryParse(windowsController.text) ?? 0,
        'hasWindows': hasWindows,
        'material': selectedMaterial ?? 'Не указано',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Комната сохранена!')),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Ошибка сохранения комнаты: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ошибка сохранения: $e"),
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
        title: Text(widget.roomId == null ? "Добавить комнату" : "Редактировать комнату"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: roomNameController,
                  decoration: const InputDecoration(labelText: "Название"),
                  validator: (value) => value!.isEmpty ? "Введите название!" : null,
                ),
                TextFormField(
                  controller: heightController,
                  decoration: const InputDecoration(labelText: "Высота (м)"),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: widthController,
                  decoration: const InputDecoration(labelText: "Ширина (м)"),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: lengthController,
                  decoration: const InputDecoration(labelText: "Длина (м)"),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: windowsController,
                  decoration: const InputDecoration(labelText: "Количество окон"),
                  keyboardType: TextInputType.number,
                ),
                CheckboxListTile(
                  title: const Text("Есть окна"),
                  value: hasWindows,
                  onChanged: (value) {
                    setState(() {
                      hasWindows = value ?? false;
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  value: (selectedMaterial != null &&
                      ["Кирпич", "Бетон", "Гипсокартон", "Дерево", "Другое"]
                          .contains(selectedMaterial))
                      ? selectedMaterial
                      : "Другое", // ✅ Исправляем ошибку: если значение не найдено, ставим "
                  decoration: const InputDecoration(labelText: "Материал стен"),
                  items: ["Кирпич", "Бетон", "Гипсокартон", "Дерево", "Другое"]
                      .map((material) => DropdownMenuItem(
                    value: material,
                    child: Text(material),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMaterial = value;
                    });
                  },
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveRoomData,
                  child: Text(widget.roomId == null ? "Добавить комнату" : "Сохранить изменения"),
                ),
                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {
                    if (widget.roomId == null) {
                    // Показываем сообщение, если комната не сохранена
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("⚠️ Сначала сохраните комнату!"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return; // Выходим из метода
                    }
                    // ✅ Убираем ошибку DropdownButton
                    if (selectedMaterial == null ||
                        !["Кирпич", "Бетон", "Гипсокартон", "Дерево", "Другое"]
                            .contains(selectedMaterial)) {
                      selectedMaterial = "Другое"; // Значение по умолчанию
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FeatureListScreen(
                          projectId: widget.projectId,
                          buildingId: widget.buildingId,
                          roomId: widget.roomId!,
                        ),
                      ),
                    );
                  },
                  child: const Text("Добавить объект (окно, дверь)"), // 🛠 ✅ Добавили child
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DesignScreen(
                          projectId: widget.projectId,
                          buildingId: widget.buildingId,
                          roomId: widget.roomId ?? "",
                        ),
                      ),
                    );
                  },
                  child: Text("Проектировать"),
                ),


              ],
            ),
          ),
        ),
      ),
    );
  }
}
