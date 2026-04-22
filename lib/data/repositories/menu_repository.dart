import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/cloudinary_services.dart';
import '../models/menu_item_model.dart';

class MenuRepository {
  final FirebaseFirestore _firestore;
  String _shopId = '';

  MenuRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  void setShopId(String shopId) {
    _shopId = shopId;
  }

  CollectionReference<Map<String, dynamic>> get _menuItemsRef {
    if (_shopId.isEmpty) {
      throw Exception('shopId is not set in MenuRepository');
    }
    return _firestore.collection('shops').doc(_shopId).collection('menu_items');
  }

  Stream<List<MenuItemModel>> getMenuItems() {
    return _menuItemsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MenuItemModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addMenuItem(MenuItemModel item, {XFile? imageFile}) async {
    String imageUrl = item.imageUrl;

    if (imageFile != null) {
      final uploadedUrl = await CloudinaryService.uploadImage(imageFile);
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      }
    }

    final newItem = MenuItemModel(
      id: item.id,
      name: item.name,
      price: item.price,
      offerPrice: item.offerPrice,
      description: item.description,
      category: item.category,
      unit: item.unit,
      available: item.available,
      imageUrl: imageUrl,
    );

    await _menuItemsRef.add(newItem.toMap());
  }

  Future<void> updateMenuItem(MenuItemModel item, {XFile? imageFile}) async {
    String imageUrl = item.imageUrl;

    if (imageFile != null) {
      final uploadedUrl = await CloudinaryService.uploadImage(imageFile);
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      }
    }

    final updatedItem = MenuItemModel(
      id: item.id,
      name: item.name,
      price: item.price,
      offerPrice: item.offerPrice,
      description: item.description,
      category: item.category,
      unit: item.unit,
      available: item.available,
      imageUrl: imageUrl,
    );

    await _menuItemsRef.doc(item.id).update(updatedItem.toMap());
  }

  Future<void> deleteMenuItem(String id) async {
    await _menuItemsRef.doc(id).delete();
  }
}
