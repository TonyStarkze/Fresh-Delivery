import 'dart:convert';
import 'dart:typed_data';
import 'package:delivery_webapp/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiImageService {
  /// Generates a food image using Hugging Face SDXL model based on the item name.
  /// Returns raw bytes on success, or null on failure.
  static Future<Uint8List?> generateFoodImage(String itemName) async {
    // 1. Validate Proxy URL
    if (aiProxyUrl.isEmpty || aiProxyUrl.contains('your-worker-name')) {
      debugPrint(
        'AI Image Service: Missing or default Proxy URL in constants.dart',
      );
      return null;
    }

    // 2. Prepare the prompt for high quality food results
    final prompt =
        '$itemName, professional food photography, '
        'white background, restaurant menu style, appetizing, high resolution, 8k';

    const url = aiProxyUrl;

    debugPrint(
      'AI Image Service (Hugging Face): Requesting image for "$itemName"...',
    );

    try {
      // 3. Fetch the image bytes via POST
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'task': 'image', 'prompt': prompt}),
          )
          .timeout(
            const Duration(seconds: 90),
          ); // Proxy can take time to load inference results

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty) {
          debugPrint('AI Image Service Error: Received empty response body.');
          return null;
        }
        debugPrint(
          'AI Image Service: Successfully generated ${response.bodyBytes.length} bytes.',
        );
        return response.bodyBytes;
      } else if (response.statusCode == 503) {
        // Model is loading (cold start)
        debugPrint('AI Image Service: Model is loading, please wait...');
        return null; // The UI should ideally handle retries or tell the user to wait
      } else {
        debugPrint(
          'AI Image Service Error: Server returned status ${response.statusCode}.',
        );
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('AI Image Service Exception: $e');
      return null;
    }
  }
}
