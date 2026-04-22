import 'dart:async';
import 'package:delivery_webapp/data/models/menu_item_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/menu_repository.dart';
import 'menu_event.dart';
import 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final MenuRepository _repository;
  MenuBloc({required MenuRepository repository})
    : _repository = repository,
      super(const MenuState()) {
    on<LoadMenuItems>(_onLoadMenuItems);
    on<UpdateMenuItemsList>(_onUpdateMenuItemsList);
    on<AddMenuItem>(_onAddMenuItem);
    on<EditMenuItem>(_onEditMenuItem);
    on<RemoveMenuItem>(_onRemoveMenuItem);
  }

  Future<void> _onLoadMenuItems(
    LoadMenuItems event,
    Emitter<MenuState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await emit.forEach<List<MenuItemModel>>(
      _repository.getMenuItems(),
      onData: (items) =>
          state.copyWith(items: items, isLoading: false, error: null),
      onError: (error, stackTrace) =>
          state.copyWith(isLoading: false, error: error.toString()),
    );
  }

  void _onUpdateMenuItemsList(
    UpdateMenuItemsList event,
    Emitter<MenuState> emit,
  ) {
    emit(state.copyWith(items: event.items, isLoading: false));
  }

  Future<void> _onAddMenuItem(
    AddMenuItem event,
    Emitter<MenuState> emit,
  ) async {
    try {
      await _repository.addMenuItem(event.item, imageFile: event.imageFile);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onEditMenuItem(
    EditMenuItem event,
    Emitter<MenuState> emit,
  ) async {
    try {
      await _repository.updateMenuItem(
        event.item,
        imageFile: event.imageFile,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRemoveMenuItem(
    RemoveMenuItem event,
    Emitter<MenuState> emit,
  ) async {
    try {
      await _repository.deleteMenuItem(event.id);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

}
