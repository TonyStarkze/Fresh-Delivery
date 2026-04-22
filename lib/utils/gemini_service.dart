import 'dart:convert';
import 'package:delivery_webapp/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  /// Generates an appetizing food description using the unified AI proxy.
  Future<String?> generateDescription({
    required String name,
    required String price,
    required String unit,
    int maxRetries = 3,
  }) async {
    // 1. Validate Proxy URL
    if (aiProxyUrl.isEmpty || aiProxyUrl.contains('your-worker-name')) {
      debugPrint('Error: AI Proxy URL not configured in constants.dart.');
      return null;
    }

    // 2. Define Prompt
    final prompt = 'Generate an appetizing, catchy, and brief menu description (max 2 sentences) for a food item named "$name". '
        'The price is $price and it comes in a quantity of "$unit". '
        'Focus on the taste and quality. Do not include the price or unit in the description text itself.';

    int delaySeconds = 2;

    for (int i = 0; i < maxRetries; i++) {
      try {
        debugPrint('Gemini Service Proxy: Requesting description for "$name"...');
        
        // 3. Send Request to Unified Proxy
        final response = await http.post(
          Uri.parse(aiProxyUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'task': 'text',
            'prompt': prompt,
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['text'] ?? 'No response generated.';
        } 
        else if (response.statusCode == 503 && i < maxRetries - 1) {
          debugPrint('Proxy/Service busy (503), retrying in $delaySeconds seconds...');
          await Future.delayed(Duration(seconds: delaySeconds));
          delaySeconds *= 2;
          continue;
        } else {
          debugPrint('Gemini Service Error: Status ${response.statusCode}');
          debugPrint('Response: ${response.body}');
          return null;
        }

      } catch (e) {
        debugPrint('Gemini Service Exception: $e');
        if (i == maxRetries - 1) {
          return null;
        }
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
      }
    }
    
    return null;
  }
}
