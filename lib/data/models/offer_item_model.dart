import 'package:equatable/equatable.dart';

class OfferItemModel extends Equatable {
  final String id;
  final String imageUrl;
  final String? title;

  const OfferItemModel({
    required this.id,
    required this.imageUrl,
    this.title,
  });

  factory OfferItemModel.fromMap(Map<String, dynamic> map, String docId) {
    return OfferItemModel(
      id: docId,
      imageUrl: map['imageUrl'] as String? ?? '',
      title: map['title'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
    };
  }

  Map<String, dynamic> toUIMap({dynamic webImage}) {
    return {
      'id': id,
      'image': imageUrl,
      'title': title,
      'webImage': webImage,
    };
  }

  OfferItemModel copyWith({
    String? imageUrl,
    String? title,
  }) {
    return OfferItemModel(
      id: id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
    );
  }

  @override
  List<Object?> get props => [id, imageUrl, title];
}
