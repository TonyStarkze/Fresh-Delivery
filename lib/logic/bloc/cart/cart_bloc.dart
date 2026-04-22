import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final updatedItems = Map<String, Map<String, dynamic>>.from(state.items);
    final name = event.item['name'] as String;

    if (updatedItems.containsKey(name)) {
      final existing = Map<String, dynamic>.from(updatedItems[name]!);
      existing['qty'] = (existing['qty'] as int) + 1;
      updatedItems[name] = existing;
    } else {
      updatedItems[name] = {
        ...event.item,
        'qty': 1,
      };
    }

    emit(state.copyWith(items: updatedItems));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final updatedItems = Map<String, Map<String, dynamic>>.from(state.items);
    final name = event.item['name'] as String;

    if (updatedItems.containsKey(name)) {
      final existing = Map<String, dynamic>.from(updatedItems[name]!);
      final currentQty = existing['qty'] as int;

      if (currentQty <= 1) {
        updatedItems.remove(name);
      } else {
        existing['qty'] = currentQty - 1;
        updatedItems[name] = existing;
      }
    }

    emit(state.copyWith(items: updatedItems));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState());
  }
}
