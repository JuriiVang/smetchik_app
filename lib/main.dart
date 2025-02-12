import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/project_list_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeFirestore(); // 🏗 Создаём структуру Firestore

  runApp(const MyApp());
}

// 🚀 Приложение
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smetchik App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ProjectListScreen(),
    );
  }
}

// 🚀 Функция инициализации Firestore (проверяет перед созданием)
Future<void> initializeFirestore() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // 🔥 1. Проверяем, существует ли проект
  DocumentReference projectRef =
      firestore.collection('projects').doc('hospital');
  var projectSnapshot = await projectRef.get();

  if (!projectSnapshot.exists) {
    await projectRef.set({
      'name': 'Госпиталь',
      'location': 'Десна',
      'description': 'Ремонт кабинетов в госпитале',
      'status': 'В работе',
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint("✅ Проект 'Госпиталь' создан.");
  }

  // 🔥 2. Проверяем, существует ли здание
  DocumentReference buildingRef =
      projectRef.collection('buildings').doc('mainBuilding');
  var buildingSnapshot = await buildingRef.get();

  if (!buildingSnapshot.exists) {
    await buildingRef.set({
      'name': 'Главный корпус',
      'floors': 3,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint("✅ Здание 'Главный корпус' создано.");
  }

  // 🔥 3. Проверяем, существует ли комната
  DocumentReference roomRef = buildingRef.collection('rooms').doc('room1');
  var roomSnapshot = await roomRef.get();

  if (!roomSnapshot.exists) {
    await roomRef.set({
      'name': 'Операционная',
      'width': 5.0,
      'height': 3.2,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint("✅ Комната 'Операционная' создана.");
  }

  // 🔥 4. Проверяем, существует ли объект в комнате (окно)
  DocumentReference featureRef = roomRef.collection('features').doc('window1');
  var featureSnapshot = await featureRef.get();

  if (!featureSnapshot.exists) {
    await featureRef.set({
      'name': 'Окно',
      'width': 1.5,
      'height': 1.2,
      'depth': 0.3,
      'material': 'Пластик',
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint("✅ Окно добавлено в 'Операционную'.");
  }

  debugPrint("🔥 Firestore структура успешно инициализирована!");
}
