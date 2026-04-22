import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:delivery_webapp/utils/cloudinary_services.dart';
import 'package:delivery_webapp/utils/gemini_service.dart';
import 'package:delivery_webapp/utils/ai_image_service.dart';

class AddOrUpdateMenuItem extends StatefulWidget {
  final Map<String, dynamic>? item;
  final List<String> allCategories;

  const AddOrUpdateMenuItem({
    super.key,
    this.item,
    required this.allCategories,
  });

  @override
  State<AddOrUpdateMenuItem> createState() => _AddOrUpdateMenuItemState();
}

class _AddOrUpdateMenuItemState extends State<AddOrUpdateMenuItem> with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController offerPriceController;
  late TextEditingController descController;
  late TextEditingController unitController;
  late String selectedCategory;
  Uint8List? webImage;
  XFile? selectedImageFile;
  late bool isAvailable;
  bool isGeneratingImage = false;
  bool isGeneratingDesc = false;
  final ImagePicker picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  // For edit mode existing image url
  String? existingImageUrl;

  bool get isGeneratingAny => isGeneratingImage || isGeneratingDesc;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    nameController = TextEditingController(text: item?['name']);
    priceController = TextEditingController(
      text: item?['price']?.toString().replaceAll('₹', '') ?? '',
    );
    // Initialize offer price — strip ₹ prefix for editing
    final rawOffer = item?['offerPrice']?.toString() ?? '';
    offerPriceController = TextEditingController(
      text: rawOffer.replaceAll('₹', ''),
    );
    descController = TextEditingController(text: item?['description'] ?? '');
    unitController = TextEditingController(text: item?['unit'] ?? '');
    final cat = item?['category'];
    if (cat != null && widget.allCategories.contains(cat)) {
      selectedCategory = cat;
    } else {
      selectedCategory = widget.allCategories.isNotEmpty
          ? widget.allCategories.first
          : '';
    }
    webImage = item?['webImage'];
    isAvailable = item?['available'] ?? true;
    existingImageUrl = item?['image'] == '' ? null : item?['image'];
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    offerPriceController.dispose();
    descController.dispose();
    unitController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateAll() async {
    if (nameController.text.trim().isEmpty) {
      _showWarning('Please enter an Item Name first!');
      return;
    }
    await Future.wait([
      _generateImage(),
      _generateDescription(),
    ]);
  }

  Future<void> _generateImage() async {
    if (nameController.text.trim().isEmpty) {
      _showWarning('Enter name to generate image.');
      return;
    }
    setState(() => isGeneratingImage = true);
    try {
      final bytes = await AiImageService.generateFoodImage(nameController.text);
      if (bytes != null) {
        setState(() {
          webImage = bytes;
          selectedImageFile = XFile.fromData(
            bytes,
            name: '${nameController.text}.jpg',
            mimeType: 'image/jpeg',
          );
          existingImageUrl = null;
        });
      } else {
        _showError('Failed to generate image.');
      }
    } finally {
      setState(() => isGeneratingImage = false);
    }
  }

  Future<void> _generateDescription() async {
    if (nameController.text.trim().isEmpty) {
      _showWarning('Enter name to generate description.');
      return;
    }
    setState(() => isGeneratingDesc = true);
    try {
      final description = await _geminiService.generateDescription(
        name: nameController.text,
        price: '₹${priceController.text.isEmpty ? "0" : priceController.text}',
        unit: unitController.text.isEmpty ? "per serving" : unitController.text,
      );
      if (description != null) {
        setState(() {
          descController.text = description;
        });
      } else {
        _showError('AI Text generation failed. Please try again or type manually.');
      }
    } finally {
      setState(() => isGeneratingDesc = false);
    }
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Item' : 'Add New Item'),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Manual Mode'),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('AI Mode '),
                      Icon(Icons.auto_awesome, size: 14, color: Colors.blueAccent),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 380, // Height for the mode-specific section
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildManualTab(),
                          _buildAiTab(),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                    // Shared Admin Details (Common for both modes)
                    _buildSharedFields(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
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
            if (nameController.text.isNotEmpty &&
                priceController.text.isNotEmpty) {
              final offerText = offerPriceController.text.trim();
              Navigator.pop(context, {
                'name': nameController.text,
                'price': '₹${priceController.text}',
                'offerPrice': offerText.isNotEmpty ? '₹$offerText' : null,
                'available': isAvailable,
                'image': existingImageUrl ?? '',
                'category': selectedCategory,
                'description': descController.text,
                'unit': unitController.text.trim(),
                'webImage': webImage,
                'imageFile': selectedImageFile,
              });
            }
          },
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Widget _buildManualTab() {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Item Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              final bytes = await image.readAsBytes();
              setState(() {
                selectedImageFile = image;
                webImage = bytes;
                existingImageUrl = null;
              });
            }
          },
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Stack(
              children: [
                if (webImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(webImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  )
                else if (existingImageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(cldUrl(existingImageUrl!), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text('Tap to upload image', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                if (webImage != null || existingImageUrl != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 10, color: Colors.white),
                        onPressed: () => setState(() {
                          webImage = null;
                          selectedImageFile = null;
                          existingImageUrl = null;
                        }),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: descController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildAiTab() {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Item Name',
            hintText: 'e.g. Paneer Tikka...',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: isGeneratingAny ? null : _generateAll,
              icon: isGeneratingAny
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, color: Colors.blueAccent),
            ),
          ),
          onSubmitted: (_) => _generateAll(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: isGeneratingImage
                          ? _PulseLoader()
                          : (webImage != null
                              ? Image.memory(webImage!, fit: BoxFit.cover)
                              : (existingImageUrl != null
                                  ? Image.network(cldUrl(existingImageUrl!), fit: BoxFit.cover)
                                  : Center(child: Icon(Icons.image_outlined, size: 40, color: Colors.grey[400])))),
                    ),
                  ),
                  if (!isGeneratingImage && (webImage != null || existingImageUrl != null))
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: ElevatedButton.icon(
                        onPressed: _generateImage,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, minimumSize: const Size(80, 32)),
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Regenerate 🔥', style: TextStyle(fontSize: 10)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Item Description',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (!isGeneratingDesc)
                    TextButton.icon(
                      onPressed: _generateDescription,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 14, color: Colors.blueAccent),
                      label: const Text('Rewrite ✨', style: TextStyle(fontSize: 11, color: Colors.blueAccent)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              if (isGeneratingDesc)
                _PulseLoader(height: 50)
              else
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'AI will write this for you...',
                    border: const OutlineInputBorder(),
                    fillColor: Colors.white.withValues(alpha: 0.8),
                    filled: true,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSharedFields() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedCategory,
          decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
          items: widget.allCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
          onChanged: (value) => setState(() => selectedCategory = value!),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price', prefixText: '₹ ', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit', hintText: 'e.g. 1 pc', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: offerPriceController,
          decoration: const InputDecoration(labelText: 'Offer Price (Optional)', prefixText: '₹ ', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Available for Sale'),
          value: isAvailable,
          onChanged: (val) => setState(() => isAvailable = val),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _PulseLoader extends StatefulWidget {
  final double height;
  const _PulseLoader({this.height = 140});

  @override
  State<_PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<_PulseLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
