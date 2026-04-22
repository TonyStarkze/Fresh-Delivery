import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/menu_item_model.dart';

abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object?> get props => [];
}

class LoadMenuItems extends MenuEvent {}

class UpdateMenuItemsList extends MenuEvent {
  final List<MenuItemModel> items;
  const UpdateMenuItemsList(this.items);

  @override
  List<Object?> get props => [items];
}

class AddMenuItem extends MenuEvent {
  final MenuItemModel item;
  final XFile? imageFile;

  const AddMenuItem(this.item, {this.imageFile});

  @override
  List<Object?> get props => [item, imageFile];
}

class EditMenuItem extends MenuEvent {
  final MenuItemModel item;
  final XFile? imageFile;

  const EditMenuItem(this.item, {this.imageFile});

  @override
  List<Object?> get props => [item, imageFile];
}

class RemoveMenuItem extends MenuEvent {
  final String id;
  const RemoveMenuItem(this.id);

  @override
  List<Object?> get props => [id];
}
