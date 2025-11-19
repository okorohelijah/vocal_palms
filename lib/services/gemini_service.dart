import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiService(this.apiKey) {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  Future<String?> analyzeImage(Uint8List imageBytes) async {
    try {
      final content = [
        Content.multi([
          TextPart(
            'What sign language gesture is shown in this image? Return ONLY the letter or word. If it is unclear or no hand is visible, return "..."',
          ),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await _model.generateContent(content);
      return response.text?.trim();
    } catch (e) {
      print('Gemini Error: $e');
      return null;
    }
  }
}
