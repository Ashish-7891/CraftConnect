import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:craftconnect/services/gemini_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('GeminiService Image Input & Dynamic Payload Tests', () {
    test('buildGenerateContentRequestBody encodes TWO DIFFERENT image inputs into different payloads', () {
      // Craft Image A (e.g. colorful painting bytes)
      final imageA = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
        10, 20, 30, 40, 50,
      ]);

      // Craft Image B (e.g. terracotta pottery bytes)
      final imageB = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
        99, 88, 77, 66, 55, 44, 33,
      ]);

      final requestA = GeminiService.buildGenerateContentRequestBody(imageBytes: imageA);
      final requestB = GeminiService.buildGenerateContentRequestBody(imageBytes: imageB);

      // Extract parts from contents
      final contentsA = requestA['contents'] as List;
      final partsA = contentsA[0]['parts'] as List;
      final inlineDataA = partsA[1]['inlineData'] as Map<String, dynamic>;

      final contentsB = requestB['contents'] as List;
      final partsB = contentsB[0]['parts'] as List;
      final inlineDataB = partsB[1]['inlineData'] as Map<String, dynamic>;

      // Verify that requests receive completely different image bytes
      expect(inlineDataA['data'], isNot(equals(inlineDataB['data'])));
      expect(inlineDataA['data'], equals(base64Encode(imageA)));
      expect(inlineDataB['data'], equals(base64Encode(imageB)));

      // Verify dynamic MIME types
      expect(inlineDataA['mimeType'], 'image/png');
      expect(inlineDataB['mimeType'], 'image/jpeg');
    });

    test('GeminiCatalogResult.fromJson dynamically parses different craft responses', () {
      // Painting response from Gemini
      final paintingJson = {
        'title': 'Handmade Madhubani Peacock Painting',
        'category': 'Paintings',
        'craftType': 'Madhubani Art',
        'material': 'Handmade Paper, Natural Pigments',
        'color': 'Multicolor with Indigo and Crimson',
        'description': 'Traditional folk painting depicting sacred peacock motif.',
        'tags': ['madhubani', 'painting', 'folk art', 'bihar'],
        'suggestedPriceMin': 1200,
        'suggestedPriceMax': 2500,
      };

      final paintingResult = GeminiCatalogResult.fromJson(paintingJson);
      expect(paintingResult.title, 'Handmade Madhubani Peacock Painting');
      expect(paintingResult.category, 'Paintings');
      expect(paintingResult.craftType, 'Madhubani Art');
      expect(paintingResult.material, 'Handmade Paper, Natural Pigments');
      expect(paintingResult.suggestedPriceMin, 1200.0);
      expect(paintingResult.suggestedPriceMax, 2500.0);
      expect(paintingResult.suggestedPriceMid, 1850.0);

      // Pottery response from Gemini
      final potteryJson = {
        'title': 'Handcrafted Terracotta Clay Water Jug',
        'category': 'Pottery',
        'craftType': 'Clay Wheel Throwing',
        'material': 'Natural River Clay',
        'color': 'Terracotta Red and Ochre',
        'description': 'Naturally cooling terracotta jug handcrafted by rural potters.',
        'tags': ['terracotta', 'pottery', 'jug', 'clay'],
        'suggestedPriceMin': 350,
        'suggestedPriceMax': 700,
      };

      final potteryResult = GeminiCatalogResult.fromJson(potteryJson);
      expect(potteryResult.title, 'Handcrafted Terracotta Clay Water Jug');
      expect(potteryResult.category, 'Pottery');
      expect(potteryResult.craftType, 'Clay Wheel Throwing');
      expect(potteryResult.suggestedPriceMid, 525.0);
    });

    test('GeminiCatalogResult.fromJson throws FormatException when title is missing', () {
      final invalidJson = {
        'category': 'Paintings',
        'craftType': 'Madhubani',
      };

      expect(
        () => GeminiCatalogResult.fromJson(invalidJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('analyzeProductImage throws Exception when key is not configured and does not return fallback', () async {
      expect(
        () => GeminiService.analyzeProductImage(
          imageBytes: Uint8List.fromList([1, 2, 3]),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('GeminiService uses gemini-3.5-flash model', () {
      expect(GeminiService.modelName, 'gemini-3.5-flash');
    });
  });
}
