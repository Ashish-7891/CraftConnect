import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CloudinaryService {
  static const String _envCloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const String _envUploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  static const String _prefCloudNameKey = 'craftconnect_cloudinary_cloud_name';
  static const String _prefUploadPresetKey = 'craftconnect_cloudinary_upload_preset';

  static String? _cachedCloudName;
  static String? _cachedUploadPreset;

  /// Retrieves the Cloudinary Cloud Name:
  /// 1. --dart-define=CLOUDINARY_CLOUD_NAME=...
  /// 2. Stored key in SharedPreferences (for on-device testing)
  static Future<String> getCloudName() async {
    if (_envCloudName.isNotEmpty) {
      return _envCloudName.trim();
    }
    if (_cachedCloudName != null && _cachedCloudName!.isNotEmpty) {
      return _cachedCloudName!;
    }
    final prefs = await SharedPreferences.getInstance();
    _cachedCloudName = prefs.getString(_prefCloudNameKey)?.trim() ?? '';
    return _cachedCloudName!;
  }

  /// Retrieves the Cloudinary Unsigned Upload Preset:
  /// 1. --dart-define=CLOUDINARY_UPLOAD_PRESET=...
  /// 2. Stored key in SharedPreferences (for on-device testing)
  static Future<String> getUploadPreset() async {
    if (_envUploadPreset.isNotEmpty) {
      return _envUploadPreset.trim();
    }
    if (_cachedUploadPreset != null && _cachedUploadPreset!.isNotEmpty) {
      return _cachedUploadPreset!;
    }
    final prefs = await SharedPreferences.getInstance();
    _cachedUploadPreset = prefs.getString(_prefUploadPresetKey)?.trim() ?? '';
    return _cachedUploadPreset!;
  }

  /// Check whether Cloudinary cloud name and unsigned preset are configured
  static Future<bool> isConfigured() async {
    final cloudName = await getCloudName();
    final uploadPreset = await getUploadPreset();
    return cloudName.isNotEmpty && uploadPreset.isNotEmpty;
  }

  /// Persist Cloudinary configuration to SharedPreferences for testing on device
  static Future<void> setConfig({
    required String cloudName,
    required String uploadPreset,
  }) async {
    _cachedCloudName = cloudName.trim();
    _cachedUploadPreset = uploadPreset.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCloudNameKey, _cachedCloudName!);
    await prefs.setString(_prefUploadPresetKey, _cachedUploadPreset!);
  }

  /// Upload an image to Cloudinary using an unsigned upload preset.
  /// Returns the secure HTTPS URL (`secure_url`).
  ///
  /// Does NOT require or accept any API Secret.
  static Future<String> uploadImage({
    required Uint8List bytes,
    String folder = 'craftconnect/products',
    String? filename,
  }) async {
    final cloudName = await getCloudName();
    final uploadPreset = await getUploadPreset();

    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary is not configured.\n'
        'Please pass:\n'
        '  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name\n'
        '  --dart-define=CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset\n'
        'Or configure it in the app settings.',
      );
    }

    final endpoint = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', endpoint);
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;

    final resolvedFilename = filename ??
        'product_${DateTime.now().millisecondsSinceEpoch}.jpg';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: resolvedFilename,
      ),
    );

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        }
        final regularUrl = data['url'] as String?;
        if (regularUrl != null && regularUrl.isNotEmpty) {
          return regularUrl.replaceFirst('http://', 'https://');
        }
        throw Exception('Cloudinary response did not contain a valid image URL');
      } else {
        String errorDetail = 'HTTP ${response.statusCode}';
        try {
          final Map<String, dynamic> errJson = jsonDecode(response.body);
          if (errJson.containsKey('error') && errJson['error'] is Map) {
            errorDetail = errJson['error']['message'] ?? errorDetail;
          }
        } catch (_) {
          errorDetail = response.body.isNotEmpty ? response.body : errorDetail;
        }

        debugPrint('Cloudinary upload failed: $errorDetail');
        throw Exception('Cloudinary upload failed: $errorDetail');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network and try again.');
    } on http.ClientException catch (e) {
      throw Exception('Network error during image upload: ${e.message}');
    } on TimeoutException {
      throw Exception('Image upload timed out. Please check your connection and try again.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unexpected error during Cloudinary upload: $e');
    }
  }
}
