import 'package:equatable/equatable.dart';
import '../../../data/models/shop_profile_model.dart';

abstract class ShopProfileEvent extends Equatable {
  const ShopProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadShopProfile extends ShopProfileEvent {}

class UpdateShopProfileState extends ShopProfileEvent {
  final ShopProfileModel profile;
  const UpdateShopProfileState(this.profile);

  @override
  List<Object?> get props => [profile];
}

class SaveShopProfile extends ShopProfileEvent {
  final ShopProfileModel profile;
  const SaveShopProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}
