import 'package:equatable/equatable.dart';
import '../../../data/models/menu_item_model.dart';

class MenuState extends Equatable {
  final List<MenuItemModel> items;
  final bool isLoading;
  final String? error;

  const MenuState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  MenuState copyWith({
    List<MenuItemModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return MenuState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [items, isLoading, error];
}
