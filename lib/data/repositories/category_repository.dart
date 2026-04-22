import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore;
  String _shopId = '';

  CategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  void setShopId(String shopId) {
    _shopId = shopId;
  }

  CollectionReference<Map<String, dynamic>> get _categoriesRef {
    if (_shopId.isEmpty) {
      throw Exception('shopId is not set in CategoryRepository');
    }
    return _firestore.collection('shops').doc(_shopId).collection('categories');
  }

  CollectionReference<Map<String, dynamic>> get _menuItemsRef {
    if (_shopId.isEmpty) {
      throw Exception('shopId is not set in CategoryRepository');
    }
    return _firestore.collection('shops').doc(_shopId).collection('menu_items');
  }

  Stream<List<CategoryModel>> getCategories() {
    return _categoriesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addCategory(CategoryModel category) async {
    await _categoriesRef.add(category.toMap());
  }

  /// Updates the category and cascades the name change to all menu items
  /// that were mapped to the old category name.
  Future<void> updateCategory(CategoryModel category,
      {required String oldCategoryName}) async {
    final batch = _firestore.batch();

    // 1. Update the category document itself
    batch.update(
      _categoriesRef.doc(category.id),
      category.toMap(),
    );

    // 2. If the name changed, update all menu items referencing the old name
    if (oldCategoryName != category.name) {
      final menuSnapshot = await _menuItemsRef
          .where('category', isEqualTo: oldCategoryName)
          .get();

      for (final doc in menuSnapshot.docs) {
        batch.update(doc.reference, {'category': category.name});
      }
    }

    await batch.commit();
  }

  /// Deletes the category and all menu items mapped to it.
  Future<void> deleteCategory(String id) async {
    // 1. Fetch the category name before deleting
    final categoryDoc = await _categoriesRef.doc(id).get();
    final categoryName = categoryDoc.data()?['name'] as String?;

    final batch = _firestore.batch();

    // 2. Delete the category document
    batch.delete(_categoriesRef.doc(id));

    // 3. Delete all menu items that belong to this category
    if (categoryName != null && categoryName.isNotEmpty) {
      final menuSnapshot = await _menuItemsRef
          .where('category', isEqualTo: categoryName)
          .get();

      for (final doc in menuSnapshot.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }
}
