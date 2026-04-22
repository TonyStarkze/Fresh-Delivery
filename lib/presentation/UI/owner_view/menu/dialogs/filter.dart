import 'package:flutter/material.dart';

class FilterMenuDialog extends StatefulWidget {
  final bool? initialAvailabilityFilter;
  final String initialSortOption;

  const FilterMenuDialog({
    super.key,
    this.initialAvailabilityFilter,
    required this.initialSortOption,
  });

  @override
  State<FilterMenuDialog> createState() => _FilterMenuDialogState();
}

class _FilterMenuDialogState extends State<FilterMenuDialog> {
  late bool? tempAvailabilityFilter;
  late String tempSortOption;

  @override
  void initState() {
    super.initState();
    tempAvailabilityFilter = widget.initialAvailabilityFilter;
    tempSortOption = widget.initialSortOption;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter & Sort'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Availability',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              RadioListTile<bool?>(
                title: const Text('All Items'),
                value: null,
                groupValue: tempAvailabilityFilter,
                onChanged: (value) {
                  setState(() => tempAvailabilityFilter = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<bool?>(
                title: const Text('Available Only'),
                value: true,
                groupValue: tempAvailabilityFilter,
                onChanged: (value) {
                  setState(() => tempAvailabilityFilter = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<bool?>(
                title: const Text('Out of Stock Only'),
                value: false,
                groupValue: tempAvailabilityFilter,
                onChanged: (value) {
                  setState(() => tempAvailabilityFilter = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              const Text(
                'Sort by',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: const Text('Default (Addition Order)'),
                value: 'default',
                groupValue: tempSortOption,
                onChanged: (value) {
                  setState(() => tempSortOption = value!);
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: const Text('Price: Low to High'),
                value: 'price_asc',
                groupValue: tempSortOption,
                onChanged: (value) {
                  setState(() => tempSortOption = value!);
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: const Text('Price: High to Low'),
                value: 'price_desc',
                groupValue: tempSortOption,
                onChanged: (value) {
                  setState(() => tempSortOption = value!);
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: const Text('Name: A to Z'),
                value: 'name_asc',
                groupValue: tempSortOption,
                onChanged: (value) {
                  setState(() => tempSortOption = value!);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Return 'reset' so the caller knows to clear everything
            Navigator.pop(context, 'reset');
          },
          child: const Text('Reset All'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context, {
              'availability': tempAvailabilityFilter,
              'sort': tempSortOption,
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
