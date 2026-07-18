import 'package:flutter/material.dart';

/// Data model for a transaction category.
class CategoryModel {
  final String id;
  final String name;
  final String color; // hex string, e.g. "#FF6B6B"
  final bool isDefault;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.isDefault,
    required this.createdAt,
  });

  Color get colorValue {
    final hex = color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#95A5A6',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'is_default': isDefault,
        'created_at': createdAt.toIso8601String(),
      };

  CategoryModel copyWith({String? name, String? color}) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      isDefault: isDefault,
      createdAt: createdAt,
    );
  }
}
