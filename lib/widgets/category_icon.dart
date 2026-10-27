import 'package:flutter/material.dart';

/// Renders a category icon inside a rounded, tinted background container.
class CategoryIcon extends StatelessWidget {
  final IconData iconData;
  final Color color;
  final double size;

  const CategoryIcon({
    super.key,
    required this.iconData,
    required this.color,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: color,
        size: size * 0.52,
      ),
    );
  }
}
