import 'package:flutter/material.dart';

class AttributeChip extends StatelessWidget {
  final String attribute;
  final IconData icon;

  const AttributeChip({super.key, required this.attribute, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey), // Grey
        const SizedBox(width: 5),
        Text(
          attribute,
          style: const TextStyle(fontSize: 12, color: Color(0xFF424242)), // Dark grey
        ),
      ],
    );
  }
}
