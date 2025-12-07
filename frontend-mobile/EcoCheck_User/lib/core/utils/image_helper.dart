/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - Image Helper for Web and Mobile
 * Handles image display for both Flutter Web and Mobile platforms
 */

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Helper class to display images that work on both Web and Mobile
class ImageHelper {
  ImageHelper._();

  /// Build image widget that works on both Web and Mobile
  /// Supports File, XFile, Uint8List, and String (URL)
  static Widget buildImage({
    required dynamic imageSource, // File, XFile, Uint8List, or String (URL)
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Handle String URL (network image)
    if (imageSource is String) {
      return Image.network(
        imageSource,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const Icon(Icons.image_not_supported);
        },
      );
    }

    // Handle Web platform
    if (kIsWeb) {
      if (imageSource is XFile) {
        return FutureBuilder<Uint8List>(
          future: imageSource.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return placeholder ?? const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData && snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) {
                  return errorWidget ?? const Icon(Icons.image_not_supported);
                },
              );
            }
            return errorWidget ?? const Icon(Icons.image_not_supported);
          },
        );
      } else if (imageSource is Uint8List) {
        return Image.memory(
          imageSource,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? const Icon(Icons.image_not_supported);
          },
        );
      }
    } else {
      // Handle Mobile platform (Android/iOS)
      if (imageSource is File) {
        return Image.file(
          imageSource,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? const Icon(Icons.image_not_supported);
          },
        );
      } else if (imageSource is XFile) {
        return Image.file(
          File(imageSource.path),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? const Icon(Icons.image_not_supported);
          },
        );
      }
    }

    // Fallback
    return errorWidget ?? const Icon(Icons.image_not_supported);
  }
}

