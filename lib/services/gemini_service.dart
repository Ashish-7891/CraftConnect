import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiCatalogResult {
  final String title;
  final String category;
  final String craftType;
  final String material;
  final String color;
  final String description;
  final List<String> tags;
  final double suggestedPriceMin;
  final double suggestedPriceMax;

  GeminiCatalogResult({
    required this.title,
    required this.category,
    required this.craftType,
    required this.material,
    required this.color,
    required this.description,
    required this.tags,
    required this.suggestedPriceMin,
    required this.suggestedPriceMax,
  });

  double get suggestedPriceMid => (suggestedPriceMin + suggestedPriceMax) / 2;

  factory GeminiCatalogResult.fromJson(Map<String, dynamic> json) {
    final title = json['title']?.toString().trim() ?? '';
    if (title.isEmpty) {
      throw const FormatException('Gemini response missing product title');
    }

    final category = json['category']?.toString().trim() ?? 'Handicrafts';
    final craftType = json['craftType']?.toString().trim() ?? '';
    final material = json['material']?.toString().trim() ?? '';
    final color = json['color']?.toString().trim() ?? '';
    final description = json['description']?.toString().trim() ?? '';

    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = (json['tags'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final minPrice = (json['suggestedPriceMin'] is num)
        ? (json['suggestedPriceMin'] as num).toDouble()
        : (double.tryParse(json['suggestedPriceMin']?.toString() ?? '') ?? 400.0);
    final maxPrice = (json['suggestedPriceMax'] is num)
        ? (json['suggestedPriceMax'] as num).toDouble()
        : (double.tryParse(json['suggestedPriceMax']?.toString() ?? '') ?? (minPrice * 2));

    return GeminiCatalogResult(
      title: title,
      category: category,
      craftType: craftType,
      material: material,
      color: color,
      description: description,
      tags: parsedTags,
      suggestedPriceMin: minPrice,
      suggestedPriceMax: maxPrice,
    );
  }
}

class GeminiService {
  static const String _defaultPrimaryModel = 'gemini-3.5-flash';
  static const String _defaultFallbackModel = 'gemini-3.5-flash';

  static const String _envModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: _defaultPrimaryModel,
  );

  static const String _envFallbackModel = String.fromEnvironment(
    'GEMINI_FALLBACK_MODEL',
    defaultValue: _defaultFallbackModel,
  );

  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _prefKey = 'craftconnect_gemini_api_key';

  static String? _cachedKey;
  static bool _isAnalyzing = false;

  /// Active primary Gemini model ID (guarantees 'models/' is never duplicated)
  static String get modelName {
    final raw = _envModel.trim().isNotEmpty ? _envModel.trim() : _defaultPrimaryModel;
    return raw.startsWith('models/') ? raw.substring(7) : raw;
  }

  /// Active fallback Gemini model ID (guarantees 'models/' is never duplicated)
  static String get fallbackModelName {
    final raw = _envFallbackModel.trim().isNotEmpty ? _envFallbackModel.trim() : _defaultFallbackModel;
    return raw.startsWith('models/') ? raw.substring(7) : raw;
  }

  /// Inspects the current Gemini API model availability for the active key
  /// to select a verified compatible fallback model that supports generateContent.
  static Future<String> resolveAvailableFallbackModel(String apiKey) async {
    try {
      final listUrl = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
      );
      final response = await http.get(
        listUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['models'] is List) {
          final List<dynamic> rawModels = data['models'];
          final availableSupportedModels = <String>{};

          for (final item in rawModels) {
            if (item is Map) {
              final name = item['name']?.toString() ?? '';
              final cleanName = name.startsWith('models/') ? name.substring(7) : name;
              final methods = item['supportedGenerationMethods'];
              if (methods is List && methods.contains('generateContent')) {
                availableSupportedModels.add(cleanName);
              }
            }
          }

          // Prioritize verified multimodal models different from the primary model
          final currentPrimary = modelName;
          const candidates = [
            'gemini-3.5-flash',
            'gemini-3.5-flash-lite',
            'gemini-3.8-flash',
            'gemini-2.0-flash',
          ];

          for (final candidate in candidates) {
            if (candidate != currentPrimary && availableSupportedModels.contains(candidate)) {
              debugPrint('Selected verified available fallback model: $candidate');
              return candidate;
            }
          }
        }
      }
    } catch (_) {
      // In case of timeout or failure, proceed safely to default verified fallback
    }

    return fallbackModelName;
  }

  /// Retrieves API key with fallback order:
  /// 1. --dart-define=GEMINI_API_KEY=...
  /// 2. Stored key in SharedPreferences (for on-device testing)
  static Future<String> getApiKey() async {
    if (_envApiKey.trim().isNotEmpty) {
      return _envApiKey.trim();
    }
    if (_cachedKey != null && _cachedKey!.trim().isNotEmpty) {
      return _cachedKey!.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    _cachedKey = prefs.getString(_prefKey)?.trim() ?? '';
    return _cachedKey!;
  }

  /// Allows setting a key directly from UI for testing when dart-define is omitted
  static Future<void> setApiKey(String key) async {
    _cachedKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _cachedKey!);
  }

  /// Builds the generateContent request payload for Gemini Vision directly from current image bytes
  static Map<String, dynamic> buildGenerateContentRequestBody({
    required Uint8List imageBytes,
    String? craftHint,
  }) {
    final base64Image = base64Encode(imageBytes);

    // Detect MIME type (default image/jpeg for image_picker compressed output)
    String mimeType = 'image/jpeg';
    if (imageBytes.length > 8 &&
        imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      mimeType = 'image/png';
    } else if (imageBytes.length > 4 &&
        imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46) {
      mimeType = 'image/webp';
    }

    final prompt = '''
You are an expert AI cataloging assistant for traditional and marginalized artisans in India (Smart India Hackathon project CraftConnect).
Analyze the attached product image and generate a rich, accurate, market-ready handicraft catalog entry.

Categories MUST be one of:
[Pottery, Textiles, Woodcraft, Jewellery, Paintings, Handicrafts, Bamboo, Metal Craft, Other]

Return a single JSON object with EXACTLY these keys:
{
  "title": "A captivating, marketable product title (e.g. Handmade Terracotta Water Jug)",
  "category": "One exact category from the list above",
  "craftType": "Specific traditional craft technique (e.g. Clay Wheel Throwing, Kalamkari, Dhokra, Block Print)",
  "material": "Primary materials used (e.g. Natural River Clay, Sheesham Wood, Pure Cotton)",
  "color": "Dominant and accent colors (e.g. Terracotta Red and Ochre)",
  "description": "Evocative, culturally rich description highlighting artisanal heritage, craftsmanship, and aesthetic value (3 to 5 sentences)",
  "tags": ["3 to 6 high-relevance search keywords"],
  "suggestedPriceMin": 450,
  "suggestedPriceMax": 950
}

Suggested prices MUST be in Indian Rupees (INR), realistic for genuine handmade artisan goods.
${craftHint != null && craftHint.isNotEmpty ? "Artisan's additional note: $craftHint" : ""}
IMPORTANT: Output ONLY the JSON object. Do not wrap in markdown quotes if possible.
''';

    return {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      }
    };
  }

  /// Real Gemini Vision call to analyze product image
  static Future<GeminiCatalogResult> analyzeProductImage({
    required Uint8List imageBytes,
    String? craftHint,
    String? language,
    void Function(String status)? onStatusUpdate,
  }) async {
    if (_isAnalyzing) {
      debugPrint('[GEMINI_DIAGNOSTIC] Duplicate request prevented! Analysis already currently active.');
      throw Exception('Gemini AI is temporarily unavailable. Please try again.');
    }
    _isAnalyzing = true;

    try {
      final apiKey = await getApiKey();
      final isKeyLoaded = apiKey.trim().isNotEmpty;

      // 3. Whether GEMINI_API_KEY is loaded (true/false only)
      debugPrint('[GEMINI_DIAGNOSTIC] 3. Whether GEMINI_API_KEY is loaded: $isKeyLoaded');

      if (!isKeyLoaded) {
        debugPrint('[GEMINI_DIAGNOSTIC] 7. Exception type/message: Exception: Gemini API Key is not configured.');
        throw Exception(
          'Gemini API Key is not configured.\n'
          'Please enter your Gemini API Key in the settings dialog or pass --dart-define=GEMINI_API_KEY=...',
        );
      }

      final primaryModel = modelName;
      // 1. Exact model name
      debugPrint('[GEMINI_DIAGNOSTIC] 1. Exact model name: $primaryModel');

      final endpointBase = 'https://generativelanguage.googleapis.com/v1beta/models/$primaryModel:generateContent';
      // 2. Exact endpoint URL, but NEVER print the API key
      debugPrint('[GEMINI_DIAGNOSTIC] 2. Exact endpoint URL: $endpointBase?key=[REDACTED]');

      // 4. Image byte size
      debugPrint('[GEMINI_DIAGNOSTIC] 4. Image byte size: ${imageBytes.length} bytes');

      // Primary Gemini generateContent REST endpoint
      final primaryUrl = Uri.parse('$endpointBase?key=$apiKey');

      final requestBody = buildGenerateContentRequestBody(
        imageBytes: imageBytes,
        craftHint: craftHint,
      );

      debugPrint('[GEMINI_DIAGNOSTIC] Sending exactly ONE generateContent request to Google (no retries)...');
      http.Response response;
      try {
        response = await http.post(
          primaryUrl,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode(requestBody),
        );
      } catch (networkError) {
        debugPrint('[GEMINI_DIAGNOSTIC] 7. Exception type/message: ${networkError.runtimeType}: $networkError');
        throw Exception('Gemini AI is temporarily unavailable. Please try again.');
      }

      // 5. HTTP status code
      debugPrint('[GEMINI_DIAGNOSTIC] 5. HTTP status code: ${response.statusCode}');

      // 6. Sanitized complete Google response body
      final sanitizedBody = response.body.replaceAll(apiKey, '[REDACTED_API_KEY]');
      debugPrint('[GEMINI_DIAGNOSTIC] 6. Sanitized complete Google response body:\n$sanitizedBody');

      if (response.statusCode == 429) {
        debugPrint('[GEMINI_DIAGNOSTIC] [HTTP 429 RATE_LIMIT] Quota or rate limit exceeded. Halting immediately without retry.');
        debugPrint('[GEMINI_DIAGNOSTIC] [HTTP 429 ERROR RESPONSE]:\n$sanitizedBody');
        throw Exception('Gemini AI is temporarily unavailable. Please try again.');
      }

      if (response.statusCode != 200) {
        debugPrint('[GEMINI_DIAGNOSTIC] 7. Exception type/message: HttpException(${response.statusCode}): Gemini returned non-200 status code');
        throw Exception('Gemini AI is temporarily unavailable. Please try again.');
      }

      // Parse 200 OK Response
      try {
        final decodedResponse = jsonDecode(response.body);
        final candidates = decodedResponse['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('Gemini AI returned empty candidates');
        }

        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          throw Exception('Gemini AI returned empty content parts');
        }

        String rawText = parts[0]['text'] ?? '';
        rawText = rawText.trim();

        // Strip markdown code fences if present
        if (rawText.startsWith('```json')) {
          rawText = rawText.substring(7);
        } else if (rawText.startsWith('```')) {
          rawText = rawText.substring(3);
        }
        if (rawText.endsWith('```')) {
          rawText = rawText.substring(0, rawText.length - 3);
        }
        rawText = rawText.trim();

        final parsedJson = jsonDecode(rawText) as Map<String, dynamic>;
        return GeminiCatalogResult.fromJson(parsedJson);
      } catch (parseError) {
        debugPrint('[GEMINI_DIAGNOSTIC] 7. Exception type/message: ${parseError.runtimeType}: $parseError');
        throw Exception('Gemini AI is temporarily unavailable. Please try again.');
      }
    } finally {
      _isAnalyzing = false;
    }
  }
}
