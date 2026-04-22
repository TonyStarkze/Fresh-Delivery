import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;

  const CategoryModel({
    required this.id,
    required this.name,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return CategoryModel(
      id: docId,
      name: map['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, name];
}
