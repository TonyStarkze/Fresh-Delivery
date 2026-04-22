import 'dart:async';
import 'package:delivery_webapp/data/models/category_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/category_repository.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository _repository;
  CategoryBloc({required CategoryRepository repository})
    : _repository = repository,
      super(const CategoryState()) {
    on<LoadCategories>(_onLoadCategories);
    on<UpdateCategoriesList>(_onUpdateCategoriesList);
    on<AddCategory>(_onAddCategory);
    on<EditCategory>(_onEditCategory);
    on<RemoveCategory>(_onRemoveCategory);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await emit.forEach<List<CategoryModel>>(
      _repository.getCategories(),
      onData: (categories) =>
          state.copyWith(categories: categories, isLoading: false, error: null),
      onError: (error, stackTrace) =>
          state.copyWith(isLoading: false, error: error.toString()),
    );
  }

  void _onUpdateCategoriesList(
    UpdateCategoriesList event,
    Emitter<CategoryState> emit,
  ) {
    emit(state.copyWith(categories: event.categories, isLoading: false));
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repository.addCategory(event.category);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onEditCategory(
    EditCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repository.updateCategory(
        event.category,
        oldCategoryName: event.oldName,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRemoveCategory(
    RemoveCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repository.deleteCategory(event.id);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

}
