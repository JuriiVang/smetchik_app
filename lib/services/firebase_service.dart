import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Для kIsWeb

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // 📌 Получение данных комнаты
  static Future<Map<String, dynamic>?> getRoomData(String projectId, String buildingId, String roomId) async {
    try {
      var roomSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('buildings')
          .doc(buildingId)
          .collection('rooms')
          .doc(roomId)
          .get();

      if (roomSnapshot.exists) {
        return roomSnapshot.data();
      }
    } catch (e) {
      debugPrint("❌ Ошибка загрузки данных комнаты: $e");
    }
    return null;
  }

  // 📌 Сохранение данных комнаты
  static Future<void> saveRoomData(String projectId, String buildingId, String roomId, String roomName, Map<String, dynamic> dimensions) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('buildings')
          .doc(buildingId)
          .collection('rooms')
          .doc(roomId)
          .set({
        "name": roomName,
        "dimensions": dimensions,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Комната сохранена в Firestore!");
    } catch (e) {
      debugPrint("❌ Ошибка сохранения комнаты: $e");
    }
  }

  // 📌 Сохранение размеров комнаты (если уже существует)
  static Future<void> saveRoomDimensions(String projectId, String buildingId, String roomId, Map<String, dynamic> dimensions) async {
    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('buildings')
          .doc(buildingId)
          .collection('rooms')
          .doc(roomId)
          .update({
        "dimensions": dimensions,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Размеры комнаты обновлены в Firestore!");
    } catch (e) {
      debugPrint("❌ Ошибка сохранения размеров: $e");
    }
  }

  // 📌 Загрузка изображения в Firebase Storage
  static Future<String?> uploadImage(Uint8List imageData, String projectId, String roomId) async {
    try {
      final ref = _storage.ref().child('room_images/$projectId/$roomId.png');
      await ref.putData(imageData);
      String downloadUrl = await ref.getDownloadURL();

      // 🔥 Сохраняем URL в Firestore
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('rooms')
          .doc(roomId)
          .update({"imageUrl": downloadUrl});

      debugPrint("✅ Изображение загружено в Firebase Storage: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      debugPrint("❌ Ошибка загрузки изображения: $e");
      return null;
    }
  }

  // 📌 Получение URL изображения комнаты
  static Future<String?> getImageUrl(String projectId, String roomId) async {
    try {
      var roomSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('rooms')
          .doc(roomId)
          .get();

      if (roomSnapshot.exists && roomSnapshot.data()?['imageUrl'] != null) {
        return roomSnapshot.data()?['imageUrl'];
      }
    } catch (e) {
      debugPrint("❌ Ошибка загрузки URL изображения: $e");
    }
    return null;
  }
}
