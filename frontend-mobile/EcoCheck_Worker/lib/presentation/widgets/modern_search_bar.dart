/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:flutter/material.dart';

class ModernSearchBar extends StatelessWidget {
  final String hint;
  final String? initialValue;
  final Function(String) onSearch;
  final VoidCallback? onClear;

  const ModernSearchBar({
    super.key,
    required this.hint,
    this.initialValue,
    required this.onSearch,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: initialValue != null && initialValue!.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: onClear,
                )
              : null,
        ),
      ),
    );
  }
}



