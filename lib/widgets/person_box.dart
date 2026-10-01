import 'package:flutter/material.dart';
import '../models/person.dart';

class PersonBox extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;
  final bool isHighlighted;

  const PersonBox({
    super.key,
    required this.person,
    required this.onTap,
    this.isHighlighted = false,
  });

  Color _getColor(String? colorName) {
    switch (colorName) {
      case 'Blue':
        return Colors.blue.shade400;
      case 'Purple':
        return Colors.purple.shade400;
      case 'Green':
        return Colors.green.shade400;
      case 'Orange':
        return Colors.orange.shade400;
      case 'Red':
        return Colors.red.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _getColor(person.branchColorName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(minWidth: 110, maxWidth: 160),
        decoration: BoxDecoration(
          color: isHighlighted ? Colors.yellow.shade100 : Colors.white,
          border: Border.all(
            color: isHighlighted ? Colors.amber.shade700 : borderColor,
            width: isHighlighted ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? Colors.amber.withOpacity(0.7)
                  : borderColor.withOpacity(0.5),
              blurRadius: isHighlighted ? 16 : 8,
              spreadRadius: isHighlighted ? 3 : 1,
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
            if (person.fatherName.isNotEmpty &&
                person.fatherName.toLowerCase() != 'root ancestor') ...[
              const SizedBox(height: 3),
              Text(
                'ولدیت: ${person.fatherName}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
