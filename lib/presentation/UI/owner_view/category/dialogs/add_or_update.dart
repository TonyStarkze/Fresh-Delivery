import 'package:delivery_webapp/data/models/category_model.dart';
import 'package:flutter/material.dart';

class AddOrUpdate extends StatefulWidget {
  final String label;
  final CategoryModel? category;

  const AddOrUpdate({super.key, required this.label, this.category});

  @override
  State<AddOrUpdate> createState() => _AddOrUpdateState();
}

class _AddOrUpdateState extends State<AddOrUpdate> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.label == 'add' ? 'Add Category' : 'Update Category',
        style: const TextStyle(
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                label: Text('Category Name'),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close popup without return
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.black)),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              Navigator.of(context).pop(name);
            }
          },
          child: const Text(
            'OK',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
