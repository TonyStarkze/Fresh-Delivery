import 'package:equatable/equatable.dart';

class CartState extends Equatable {
  /// Map of item name -> { ...item data, 'qty': int }
  final Map<String, Map<String, dynamic>> items;

  const CartState({this.items = const {}});

  int get totalItems => items.values.fold(0, (sum, item) => sum + (item['qty'] as int));

  double get totalPrice {
    double total = 0;
    for (final item in items.values) {
      // Use offerPrice if available, otherwise fall back to price
      final offerPrice = item['offerPrice'] as String?;
      final rawPrice = (offerPrice != null && offerPrice.isNotEmpty)
          ? offerPrice
          : item['price'] as String;
      final priceStr = rawPrice.replaceAll('₹', '').trim();
      final price = double.tryParse(priceStr) ?? 0;
      total += price * (item['qty'] as int);
    }
    return total;
  }

  int getQty(String itemName) {
    return (items[itemName]?['qty'] as int?) ?? 0;
  }

  CartState copyWith({Map<String, Map<String, dynamic>>? items}) {
    return CartState(items: items ?? this.items);
  }

  @override
  List<Object?> get props => [items];
}
