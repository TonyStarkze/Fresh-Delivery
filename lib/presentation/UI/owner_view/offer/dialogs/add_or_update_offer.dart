import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_webapp/utils/cloudinary_services.dart';

class AddOrUpdateOfferDialog extends StatefulWidget {
  final Map<String, dynamic>? item;

  const AddOrUpdateOfferDialog({super.key, this.item});

  @override
  State<AddOrUpdateOfferDialog> createState() => _AddOrUpdateOfferDialogState();
}

class _AddOrUpdateOfferDialogState extends State<AddOrUpdateOfferDialog> {
  late TextEditingController titleController;
  Uint8List? webImage;
  XFile? selectedImageFile;
  bool isPickingImage = false;
  final ImagePicker picker = ImagePicker();
  
  // For edit mode existing image url
  String? existingImageUrl;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    titleController = TextEditingController(text: item?['title'] ?? '');
    webImage = item?['webImage'];
    existingImageUrl = item?['image'] == '' ? null : item?['image'];
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    
    return AlertDialog(
      title: Text(isEdit ? 'Edit Offer Banner' : 'Add New Offer Banner'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Banner aspect ratio instruction
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Upload a landscape banner image (e.g. 16:9 or 2:1 ratio).',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  setState(() => isPickingImage = true);
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setState(() {
                        selectedImageFile = image;
                        webImage = bytes;
                      });
                    }
                  } catch (e) {
                    debugPrint('Error picking image: $e');
                  } finally {
                    setState(() => isPickingImage = false);
                  }
                },
                child: Container(
                  height: 180, // Taller area for landscape banners
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: isPickingImage
                      ? const Center(child: CircularProgressIndicator())
                      : Stack(
                          children: [
                            if (webImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  webImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            else if (existingImageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  cldUrl(existingImageUrl!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            else
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 40,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to upload banner',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            if (webImage != null || existingImageUrl != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImageFile = null;
                                      webImage = null;
                                      existingImageUrl = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title / Description (optional)',
                  hintText: 'e.g. 50% Off Pizza',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
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
            if (webImage == null && existingImageUrl == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Banner image is required!')),
              );
              return;
            }

            Navigator.pop(context, {
              'title': titleController.text.trim(),
              'image': existingImageUrl ?? '',
              'webImage': webImage,
              'imageFile': selectedImageFile,
            });
          },
          child: Text(isEdit ? 'Save' : 'Add Banner'),
        ),
      ],
    );
  }
}
