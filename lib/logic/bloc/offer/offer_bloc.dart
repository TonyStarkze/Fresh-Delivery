import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/offer_item_model.dart';
import '../../../data/repositories/offer_repository.dart';
import 'offer_event.dart';
import 'offer_state.dart';

class OfferBloc extends Bloc<OfferEvent, OfferState> {
  final OfferRepository _repository;

  OfferBloc({required OfferRepository repository})
      : _repository = repository,
        super(const OfferState()) {
    on<LoadOffers>(_onLoadOffers);
    on<UpdateOffersList>(_onUpdateOffersList);
    on<AddOffer>(_onAddOffer);
    on<EditOffer>(_onEditOffer);
    on<RemoveOffer>(_onRemoveOffer);
  }

  Future<void> _onLoadOffers(
    LoadOffers event,
    Emitter<OfferState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await emit.forEach<List<OfferItemModel>>(
      _repository.getOffers(),
      onData: (offers) =>
          state.copyWith(offers: offers, isLoading: false, error: null),
      onError: (error, stackTrace) =>
          state.copyWith(isLoading: false, error: error.toString()),
    );
  }

  void _onUpdateOffersList(
    UpdateOffersList event,
    Emitter<OfferState> emit,
  ) {
    emit(state.copyWith(offers: event.offers, isLoading: false));
  }

  Future<void> _onAddOffer(
    AddOffer event,
    Emitter<OfferState> emit,
  ) async {
    try {
      await _repository.addOffer(event.offer, imageFile: event.imageFile);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onEditOffer(
    EditOffer event,
    Emitter<OfferState> emit,
  ) async {
    try {
      await _repository.updateOffer(
        event.offer,
        imageFile: event.imageFile,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRemoveOffer(
    RemoveOffer event,
    Emitter<OfferState> emit,
  ) async {
    try {
      await _repository.deleteOffer(event.id);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
