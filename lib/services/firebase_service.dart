import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // ✅ Добавлен import

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 📌 Сохранение размеров в Firestore
  static Future<void> saveRoomDimensions(
      String projectId, String buildingId, String? roomId, Map<String, dynamic> dimensions) async {
    if (roomId == null || roomId.isEmpty) {
      debugPrint("❌ Ошибка: roomId не может быть null или пустым.");
      return;
    }

    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('buildings')
          .doc(buildingId)
          .collection('rooms')
          .doc(roomId)
          .set({
        "dimensions": dimensions,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // ✅ merge = true, чтобы не перезаписывать весь документ

      debugPrint("✅ Размеры сохранены в Firestore: $dimensions");
    } catch (e) {
      debugPrint("❌ Ошибка сохранения данных в Firestore: $e");
    }
  }
}
