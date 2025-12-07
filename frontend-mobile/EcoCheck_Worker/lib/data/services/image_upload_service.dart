/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import '../../core/constants/api_constants.dart';

class ImageUploadService {
  // Use Render production URL
  static String get baseUrl => ApiConstants.baseUrl;

  /// Compress image before upload to reduce size
  Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Return original if compression fails
    }
  }

  /// Upload single image to backend
  Future<String?> uploadImage(File imageFile) async {
    try {
      print('📤 [Upload] Starting upload for: ${imageFile.path}');
      print('📤 [Upload] Base URL: $baseUrl');

      // Compress image first
      final compressedFile = await compressImage(imageFile);
      if (compressedFile == null) {
        throw Exception('Failed to compress image');
      }

      print('📤 [Upload] Compressed to: ${compressedFile.path}');
      final uri = Uri.parse('$baseUrl/api/upload');
      print('📤 [Upload] URI: $uri');

      final request = http.MultipartRequest('POST', uri);

      // Add image file with explicit content type
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          compressedFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      print('📤 [Upload] Sending request...');
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📤 [Upload] Status: ${response.statusCode}');
      print('📤 [Upload] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final url = data['url'] as String?;
        print('📤 [Upload] Success! URL: $url');
        return url;
      } else {
        print('❌ [Upload] Failed: ${response.statusCode} - ${response.body}');
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [Upload] Error: $e');
      rethrow; // Re-throw to let caller handle
    }
  }

  /// Upload multiple images to backend
  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    try {
      print(
        '📤 [Upload Multiple] Starting upload for ${imageFiles.length} images',
      );
      print('📤 [Upload Multiple] Base URL: $baseUrl');

      final uri = Uri.parse('$baseUrl/api/upload/multiple');
      print('📤 [Upload Multiple] URI: $uri');

      final request = http.MultipartRequest('POST', uri);

      // Compress and add all images
      for (var i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        print(
          '📤 [Upload Multiple] Compressing image ${i + 1}/${imageFiles.length}',
        );

        final compressedFile = await compressImage(imageFile);
        if (compressedFile != null) {
          final multipartFile = await http.MultipartFile.fromPath(
            'images',
            compressedFile.path,
            contentType: MediaType('image', 'jpeg'),
          );
          request.files.add(multipartFile);
          print(
            '📤 [Upload Multiple] Added image ${i + 1}: ${compressedFile.path} (type: ${multipartFile.contentType})',
          );
        } else {
          print('⚠️ [Upload Multiple] Failed to compress image ${i + 1}');
        }
      }

      print(
        '📤 [Upload Multiple] Sending request with ${request.files.length} files...',
      );
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📤 [Upload Multiple] Status: ${response.statusCode}');
      print('📤 [Upload Multiple] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final images = data['images'] as List<dynamic>;
        final urls = images.map((img) => img['url'] as String).toList();
        print('📤 [Upload Multiple] Success! Uploaded ${urls.length} images');
        return urls;
      } else {
        print(
          '❌ [Upload Multiple] Failed: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Upload failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ [Upload Multiple] Error: $e');
      rethrow; // Re-throw to let caller handle
    }
  }
}
