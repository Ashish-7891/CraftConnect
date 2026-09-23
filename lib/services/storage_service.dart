import 'dart:io';
import 'package:flutter/foundation.dart';
import 'cloudinary_service.dart';

/// Legacy StorageService adapter.
/// Firebase Storage has been replaced with Cloudinary for product image hosting
/// to maintain Firebase Spark (free) tier compliance.
class StorageService {
  /// Upload product image via Cloudinary unsigned upload preset.
  /// Returns secure HTTPS URL.
  Future<String> uploadProductImage({
    required String artisanId,
    required String productId,
    File? file,
    Uint8List? bytes,
  }) async {
    Uint8List? uploadBytes = bytes;
    if (uploadBytes == null && file != null) {
      uploadBytes = await file.readAsBytes();
    }
    if (uploadBytes == null) {
      throw Exception('No image bytes provided for upload');
    }

    return await CloudinaryService.uploadImage(
      bytes: uploadBytes,
      folder: 'craftconnect/products/$artisanId',
      filename: '$productId.jpg',
    );
  }

  /// Upload user profile picture via Cloudinary unsigned upload preset.
  Future<String> uploadProfileImage({
    required String userId,
    File? file,
    Uint8List? bytes,
  }) async {
    Uint8List? uploadBytes = bytes;
    if (uploadBytes == null && file != null) {
      uploadBytes = await file.readAsBytes();
    }
    if (uploadBytes == null) {
      throw Exception('No image bytes provided for upload');
    }

    return await CloudinaryService.uploadImage(
      bytes: uploadBytes,
      folder: 'craftconnect/users/$userId',
      filename: 'profile.jpg',
    );
  }
}
