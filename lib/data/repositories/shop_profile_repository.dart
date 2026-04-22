import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_profile_model.dart';

class ShopProfileRepository {
  final FirebaseFirestore _firestore;
  String _shopId = '';

  ShopProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  void setShopId(String shopId) {
    _shopId = shopId;
  }

  DocumentReference<Map<String, dynamic>> get _profileRef {
    if (_shopId.isEmpty) {
      throw Exception('shopId is not set in ShopProfileRepository');
    }
    return _firestore
        .collection('shops')
        .doc(_shopId)
        .collection('settings')
        .doc('profile');
  }

  Stream<ShopProfileModel> getShopProfile() {
    return _profileRef.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return const ShopProfileModel(
          name: 'My Shop',
          whatsappNumber: '',
          timings: '09:00 AM - 09:00 PM',
          isOpen: true,
        );
      }
      return ShopProfileModel.fromMap(snapshot.data());
    });
  }

  Future<void> updateShopProfile(ShopProfileModel profile) async {
    await _profileRef.set(profile.toMap(), SetOptions(merge: true));
  }
}
