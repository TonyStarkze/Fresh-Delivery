import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final Map<String, dynamic> item;

  const AddToCart({required this.item});

  @override
  List<Object?> get props => [item['name']];
}

class RemoveFromCart extends CartEvent {
  final Map<String, dynamic> item;

  const RemoveFromCart({required this.item});

  @override
  List<Object?> get props => [item['name']];
}

class ClearCart extends CartEvent {
  const ClearCart();
}
