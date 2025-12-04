/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';

/// Eco Tips Carousel Widget
class EcoTipsCarousel extends StatelessWidget {
  const EcoTipsCarousel({super.key});

  final List<Map<String, String>> _tips = const [
    {
      'icon': '🌱',
      'title': 'Phân loại rác đúng cách',
      'description': 'Hãy phân loại rác tại nguồn để dễ dàng tái chế',
    },
    {
      'icon': '♻️',
      'title': 'Tái sử dụng túi nhựa',
      'description': 'Sử dụng túi vải thay vì túi nhựa một lần',
    },
    {
      'icon': '🌍',
      'title': 'Tiết kiệm năng lượng',
      'description': 'Tắt điện khi không sử dụng để giảm CO2',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tips.length,
        itemBuilder: (context, index) =>
            EcoTipCard(tip: _tips[index], isLast: index == _tips.length - 1),
      ),
    );
  }
}

/// Eco Tip Card
class EcoTipCard extends StatelessWidget {
  final Map<String, String> tip;
  final bool isLast;

  const EcoTipCard({super.key, required this.tip, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: isLast ? 0 : 12),
      child: Card(
        color: AppColors.primary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(tip['icon']!, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tip['title']!,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip['description']!,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
