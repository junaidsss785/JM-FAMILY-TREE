import 'package:flutter/material.dart';
import '../models/person.dart';

class PersonBox extends StatelessWidget {
  final Person person;
  final Person? parent;
  final VoidCallback onTap;

  const PersonBox({
    super.key,
    required this.person,
    required this.parent,
    required this.onTap,
  });

  Color _getColor(String? colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red.shade400;
      case 'blue':
        return Colors.blue.shade400;
      case 'green':
        return Colors.green.shade400;
      case 'orange':
        return Colors.orange.shade400;
      case 'purple':
        return Colors.purple.shade400;
      case 'teal':
        return Colors.teal.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _getColor(person.branchColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(minWidth: 110, maxWidth: 160),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              person.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            if (parent != null) ...[
              const SizedBox(height: 3),
              Text(
                'ولدیت: ${parent!.name}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
