// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> saveImageUrl({
    required String userId,
    required String imageUrl,
  }) async {
    await _db.collection('users').doc(userId).set({
      'profileImageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
