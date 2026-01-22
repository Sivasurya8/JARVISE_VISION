import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;
  // TODO: Replace with your actual Gemini API Key
  static const String _apiKey = 'AIzaSyDrPShTJqUQB4Qlgr4BgoNvhdiP1bijZ0s';

  // JARVIS Persona Prompt
  static const String _systemInstruction = '''
  You are JARVIS, a highly advanced AI assistant. 
  Your tone is polite, concise, and futuristic. 
  You are helpful, intelligent, and always address the user as "Sir" or "Boss".
  Keep responses short and conversational, suitable for voice output.
  When analyzing images, provide insightful and technical details.
  ''';

  Future<void> init() async {
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview', // Updated to latest preview
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemInstruction),
    );
  }

  Future<String> chat(String prompt, [Uint8List? imageBytes]) async {
    try {
      final content = [
        if (imageBytes != null) ...[
           Content.multi([
             TextPart(prompt),
             DataPart('image/jpeg', imageBytes),
           ])
        ] else ...[
           Content.text(prompt)
        ]
      ];

      // Since the API expects a list of Contents, we wrap our content item or create a specialized call
      // GenerativeModel.generateContent takes [Content].
      // If we are starting a chat, we might want 'startChat'. But for single turn vision, generateContent is fine.
      
      final response = await _model.generateContent(content);
      return response.text ?? "I'm sorry, I couldn't process that.";
    } catch (e) {
      return "Error accessing my systems: $e";
    }
  }

  // Streaming response (optional, for cooler effect)
  Stream<String> streamChat(String prompt, [Uint8List? imageBytes]) async* {
     try {
       final content = [
        if (imageBytes != null) ...[
           Content.multi([
             TextPart(prompt),
             DataPart('image/jpeg', imageBytes),
           ])
        ] else ...[
           Content.text(prompt)
        ]
      ];
      final response = _model.generateContentStream(content);
      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      yield "Error accessing my systems: $e";
    }
  }
}
