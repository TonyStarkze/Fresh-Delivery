import 'dart:async';
import 'package:delivery_webapp/data/models/shop_profile_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/shop_profile_repository.dart';
import 'shop_profile_event.dart';
import 'shop_profile_state.dart';

class ShopProfileBloc extends Bloc<ShopProfileEvent, ShopProfileState> {
  final ShopProfileRepository _repository;
  ShopProfileBloc({required ShopProfileRepository repository})
    : _repository = repository,
      super(const ShopProfileState()) {
    on<LoadShopProfile>(_onLoadShopProfile);
    on<UpdateShopProfileState>(_onUpdateShopProfileState);
    on<SaveShopProfile>(_onSaveShopProfile);
  }

  Future<void> _onLoadShopProfile(
    LoadShopProfile event,
    Emitter<ShopProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await emit.forEach<ShopProfileModel>(
      _repository.getShopProfile(),
      onData: (profile) =>
          state.copyWith(profile: profile, isLoading: false, error: null),
      onError: (error, stackTrace) =>
          state.copyWith(isLoading: false, error: error.toString()),
    );
  }

  void _onUpdateShopProfileState(
    UpdateShopProfileState event,
    Emitter<ShopProfileState> emit,
  ) {
    emit(state.copyWith(profile: event.profile, isLoading: false));
  }

  Future<void> _onSaveShopProfile(
    SaveShopProfile event,
    Emitter<ShopProfileState> emit,
  ) async {
    try {
      await _repository.updateShopProfile(event.profile);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

}
