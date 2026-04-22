import 'package:equatable/equatable.dart';
import '../../../data/models/category_model.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryEvent {}

class UpdateCategoriesList extends CategoryEvent {
  final List<CategoryModel> categories;
  const UpdateCategoriesList(this.categories);

  @override
  List<Object?> get props => [categories];
}

class AddCategory extends CategoryEvent {
  final CategoryModel category;
  const AddCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class EditCategory extends CategoryEvent {
  final CategoryModel category;
  final String oldName;
  const EditCategory(this.category, {required this.oldName});

  @override
  List<Object?> get props => [category, oldName];
}

class RemoveCategory extends CategoryEvent {
  final String id;
  const RemoveCategory(this.id);

  @override
  List<Object?> get props => [id];
}
