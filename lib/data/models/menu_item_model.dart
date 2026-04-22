import 'package:equatable/equatable.dart';

class MenuItemModel extends Equatable {
  final String id;
  final String name;
  final String price; // Storing as String to match existing '₹12.99' or keeping it flexible
  final String? offerPrice; // Optional discounted price (e.g. '₹99')
  final String? description;
  final String category;
  final String? unit;
  final bool available;
  final String imageUrl;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.offerPrice,
    this.description,
    required this.category,
    this.unit,
    required this.available,
    required this.imageUrl,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String docId) {
    return MenuItemModel(
      id: docId,
      name: map['name'] as String? ?? '',
      price: map['price'] as String? ?? '0',
      offerPrice: map['offerPrice'] as String?,
      description: map['description'] as String?,
      category: map['category'] as String? ?? '',
      unit: map['unit'] as String?,
      available: map['available'] as bool? ?? true,
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'offerPrice': offerPrice,
      'description': description,
      'category': category,
      'unit': unit,
      'available': available,
      'imageUrl': imageUrl,
    };
  }

  // To easily convert to the generic Map that cart and UI currently expects
  Map<String, dynamic> toUIMap({dynamic webImage}) {
    return {
      'id': id,
      'name': name,
      'price': price,
      'offerPrice': offerPrice,
      'description': description,
      'category': category,
      'unit': unit,
      'available': available,
      'image': imageUrl,
      'webImage': webImage, // For passing the loaded Uint8List around if needed
    };
  }

  /// Returns the effective price for calculations (offerPrice if set, otherwise price).
  String get effectivePrice => (offerPrice != null && offerPrice!.isNotEmpty) ? offerPrice! : price;

  /// Whether this item currently has an active offer.
  bool get hasOffer => offerPrice != null && offerPrice!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        name,
        price,
        offerPrice,
        description,
        category,
        unit,
        available,
        imageUrl,
      ];
}
