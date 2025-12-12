import 'package:flutter/material.dart';

class ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const ReadOnlyField({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          fillColor: Theme.of(context).colorScheme.background,
        ),
        child: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}