import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // XFile lives here
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:delivery_webapp/utils/constants.dart';

class CloudinaryService {
  static const String _cloudName = cloudinaryCloudName;
  static const String _uploadPreset = cloudinaryUploadPreset;

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Uploads an [XFile] (web-compatible) to Cloudinary.
  /// Returns the secure_url string, or null on failure.
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      List<int> bytes;

      if (kIsWeb) {
        final originalBytes = await imageFile.readAsBytes(); // ✅ works on web
        try {
          bytes = await FlutterImageCompress.compressWithList(
            originalBytes,
            quality: 70, // good enough for food images
          );
        } catch (e) {
          debugPrint('Web compression failed: $e');
          bytes = originalBytes;
        }
      } else {
        final compressed = await FlutterImageCompress.compressWithFile(
          imageFile.path,
          quality: 70, // good enough for food images
        );
        bytes = compressed ?? await imageFile.readAsBytes();
      }

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.fields['upload_preset'] = _uploadPreset;

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name, // e.g. "photo.jpg"
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      } else {
        final error = jsonDecode(response.body);
        debugPrint('Cloudinary error: ${error['error']['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload exception: $e');
      return null;
    }
  }

  /// Uploads raw [Uint8List] bytes to Cloudinary.
  /// Returns the secure_url string, or null on failure.
  static Future<String?> uploadBytes(Uint8List bytes, String filename) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      } else {
        final error = jsonDecode(response.body);
        debugPrint('Cloudinary error: ${error['error']['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('Upload exception: $e');
      return null;
    }
  }
}

/// Helper to request optimized/resized images from Cloudinary.
String cldUrl(String url, {int width = 400}) {
  if (!url.contains('/upload/')) return url; // just in case it's not a standard cloudinary URI
  return url.replaceFirst('/upload/', '/upload/w_$width,f_auto,q_auto/');
}
