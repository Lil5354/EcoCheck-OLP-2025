/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';

/// Photo Picker Widget
class PhotoPicker extends StatelessWidget {
  final List<String> photos;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;

  const PhotoPicker({
    super.key,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...photos.asMap().entries.map((entry) {
          return PhotoPreview(
            photo: entry.value,
            onRemove: () => onRemovePhoto(entry.key),
          );
        }),
        if (photos.length < 5) AddPhotoButton(onTap: onAddPhoto),
      ],
    );
  }
}

/// Photo Preview Widget
class PhotoPreview extends StatelessWidget {
  final String photo;
  final VoidCallback onRemove;

  const PhotoPreview({super.key, required this.photo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image, color: AppColors.grey, size: 40),
              const SizedBox(height: 4),
              Text(
                photo,
                style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton(
            onPressed: onRemove,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: AppColors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// Add Photo Button Widget
class AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddPhotoButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo, color: AppColors.primary, size: 32),
            const SizedBox(height: 4),
            Text(
              'Thêm ảnh',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
