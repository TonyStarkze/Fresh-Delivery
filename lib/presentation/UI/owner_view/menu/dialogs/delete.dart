import 'package:flutter/material.dart';

class DeleteMenuItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const DeleteMenuItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Item'),
      content: Text('Are you sure you want to delete "${item['name']}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
