import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/offer_item_model.dart';

abstract class OfferEvent extends Equatable {
  const OfferEvent();

  @override
  List<Object?> get props => [];
}

class LoadOffers extends OfferEvent {}

class UpdateOffersList extends OfferEvent {
  final List<OfferItemModel> offers;
  const UpdateOffersList(this.offers);

  @override
  List<Object?> get props => [offers];
}

class AddOffer extends OfferEvent {
  final OfferItemModel offer;
  final XFile? imageFile;
  const AddOffer(this.offer, {this.imageFile});

  @override
  List<Object?> get props => [offer, imageFile];
}

class EditOffer extends OfferEvent {
  final OfferItemModel offer;
  final XFile? imageFile;
  const EditOffer(this.offer, {this.imageFile});

  @override
  List<Object?> get props => [offer, imageFile];
}

class RemoveOffer extends OfferEvent {
  final String id;
  const RemoveOffer(this.id);

  @override
  List<Object?> get props => [id];
}
