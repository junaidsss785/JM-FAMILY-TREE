import 'package:flutter/material.dart';
import '../models/person.dart';

class PersonBox extends StatelessWidget {
  final Person person;
  final Person? parent;
  final VoidCallback onTap;
  final bool isHighlighted;

  const PersonBox({
    super.key,
    required this.person,
    required this.parent,
    required this.onTap,
    this.isHighlighted = false,
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
      case 'pink':
        return Colors.pink.shade400;
      case 'amber':
        return Colors.amber.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _getColor(person.branchColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isHighlighted ? Colors.black : Colors.black87,
                ),
              ),
              if (parent != null) ...[
                const SizedBox(height: 3),
                Text(
                  'ولدیت: ${parent!.name}',
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
      ),
    );
  }
}
