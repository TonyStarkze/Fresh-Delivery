import 'package:equatable/equatable.dart';
import '../../../data/models/shop_profile_model.dart';

class ShopProfileState extends Equatable {
  final ShopProfileModel profile;
  final bool isLoading;
  final String? error;

  const ShopProfileState({
    this.profile = const ShopProfileModel(
      name: 'My Shop',
      whatsappNumber: '',
      timings: '09:00 AM - 09:00 PM',
      isOpen: true,
    ),
    this.isLoading = false,
    this.error,
  });

  ShopProfileState copyWith({
    ShopProfileModel? profile,
    bool? isLoading,
    String? error,
  }) {
    return ShopProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [profile, isLoading, error];
}
