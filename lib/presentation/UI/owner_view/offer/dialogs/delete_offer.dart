import 'package:flutter/material.dart';

class DeleteOfferDialog extends StatelessWidget {
  final Map<String, dynamic> item;

  const DeleteOfferDialog({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? 'this banner';
    final hasTitle = title != null && title.isNotEmpty;

    return AlertDialog(
      title: const Text('Delete Banner'),
      content: Text(
        'Are you sure you want to delete ${hasTitle ? '"$title"' : 'this banner'}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
