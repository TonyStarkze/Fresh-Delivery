import 'package:equatable/equatable.dart';

class ShopProfileModel extends Equatable {
  final String name;
  final String whatsappNumber;
  final String timings;
  final bool isOpen;
  /// Delivery time in minutes. 0 or null means "Instant Delivery".
  final int deliveryTimeMinutes;

  const ShopProfileModel({
    required this.name,
    required this.whatsappNumber,
    required this.timings,
    required this.isOpen,
    this.deliveryTimeMinutes = 0,
  });

  factory ShopProfileModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const ShopProfileModel(
        name: 'My Shop',
        whatsappNumber: '',
        timings: '09:00 AM - 09:00 PM',
        isOpen: true,
        deliveryTimeMinutes: 0,
      );
    }
    return ShopProfileModel(
      name: map['name'] as String? ?? 'My Shop',
      whatsappNumber: map['whatsappNumber'] as String? ?? '',
      timings: map['timings'] as String? ?? '09:00 AM - 09:00 PM',
      isOpen: map['isOpen'] as bool? ?? true,
      deliveryTimeMinutes: map['deliveryTimeMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'whatsappNumber': whatsappNumber,
      'timings': timings,
      'isOpen': isOpen,
      'deliveryTimeMinutes': deliveryTimeMinutes,
    };
  }

  ShopProfileModel copyWith({
    String? name,
    String? whatsappNumber,
    String? timings,
    bool? isOpen,
    int? deliveryTimeMinutes,
  }) {
    return ShopProfileModel(
      name: name ?? this.name,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      timings: timings ?? this.timings,
      isOpen: isOpen ?? this.isOpen,
      deliveryTimeMinutes: deliveryTimeMinutes ?? this.deliveryTimeMinutes,
    );
  }

  /// Returns a human-readable delivery time string, or null for instant.
  String? get deliveryTimeLabel {
    if (deliveryTimeMinutes <= 0) return null;
    if (deliveryTimeMinutes < 60) {
      return 'Delivery within $deliveryTimeMinutes min';
    }
    // Check for full days (1440 minutes = 1 day)
    if (deliveryTimeMinutes >= 1440 && deliveryTimeMinutes % 1440 == 0) {
      final days = deliveryTimeMinutes ~/ 1440;
      return 'Delivery within $days day${days > 1 ? 's' : ''}';
    }
    final hours = deliveryTimeMinutes ~/ 60;
    final mins = deliveryTimeMinutes % 60;
    if (mins == 0) {
      return 'Delivery within $hours hour${hours > 1 ? 's' : ''}';
    }
    return 'Delivery within $hours hr ${mins} min';
  }

  @override
  List<Object?> get props =>
      [name, whatsappNumber, timings, isOpen, deliveryTimeMinutes];
}
