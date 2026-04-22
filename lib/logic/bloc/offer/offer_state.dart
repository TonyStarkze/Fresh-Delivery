import 'package:equatable/equatable.dart';
import '../../../data/models/offer_item_model.dart';

class OfferState extends Equatable {
  final List<OfferItemModel> offers;
  final bool isLoading;
  final String? error;

  const OfferState({
    this.offers = const [],
    this.isLoading = false,
    this.error,
  });

  OfferState copyWith({
    List<OfferItemModel>? offers,
    bool? isLoading,
    String? error,
  }) {
    return OfferState(
      offers: offers ?? this.offers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [offers, isLoading, error];
}
