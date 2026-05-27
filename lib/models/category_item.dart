import 'package:flutter/material.dart';

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_codepoint': icon.codePoint,
      'color_value': color.toARGB32(),
    };
  }

  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    return CategoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      // ignore: non_const_argument_for_const_parameter
      icon: IconData(map['icon_codepoint'] as int, fontFamily: 'MaterialIcons'),
      color: Color(map['color_value'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
