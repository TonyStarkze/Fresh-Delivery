import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/cloudinary_services.dart';
import '../models/offer_item_model.dart';

class OfferRepository {
  final FirebaseFirestore _firestore;
  String _shopId = '';

  OfferRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  void setShopId(String shopId) {
    _shopId = shopId;
  }

  CollectionReference<Map<String, dynamic>> get _offersRef {
    if (_shopId.isEmpty) {
      throw Exception('shopId is not set in OfferRepository');
    }
    return _firestore.collection('shops').doc(_shopId).collection('offers');
  }

  Stream<List<OfferItemModel>> getOffers() {
    return _offersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return OfferItemModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addOffer(OfferItemModel item, {XFile? imageFile}) async {
    String imageUrl = item.imageUrl;

    if (imageFile != null) {
      final uploadedUrl = await CloudinaryService.uploadImage(imageFile);
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      }
    }

    final newItem = OfferItemModel(
      id: item.id,
      imageUrl: imageUrl,
      title: item.title,
    );

    await _offersRef.add(newItem.toMap());
  }

  Future<void> updateOffer(OfferItemModel item, {XFile? imageFile}) async {
    String imageUrl = item.imageUrl;

    if (imageFile != null) {
      final uploadedUrl = await CloudinaryService.uploadImage(imageFile);
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      }
    }

    final updatedItem = OfferItemModel(
      id: item.id,
      imageUrl: imageUrl,
      title: item.title,
    );

    await _offersRef.doc(item.id).update(updatedItem.toMap());
  }

  Future<void> deleteOffer(String id) async {
    await _offersRef.doc(id).delete();
  }
}
