import 'package:flutter/material.dart';

/// App Color Palette
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors
  static const Color primary = Color(0xFF2ECC71); // Green
  static const Color primaryDark = Color(0xFF27AE60);
  static const Color primaryLight = Color(0xFF58D68D);

  // Secondary Colors
  static const Color secondary = Color(0xFF3498DB); // Blue
  static const Color accent = Color(0xFFE74C3C); // Red

  // Waste Type Colors
  static const Color wasteOrganic = Color(0xFF8BC34A); // Light Green
  static const Color wasteRecyclable = Color(0xFF2196F3); // Blue
  static const Color wasteHazardous = Color(0xFFFF5722); // Deep Orange
  static const Color wasteGeneral = Color(0xFF9E9E9E); // Grey
  static const Color wasteElectronic = Color(0xFF9C27B0); // Purple

  // Legacy names (for backward compatibility)
  static const Color organic = wasteOrganic;
  static const Color recyclable = wasteRecyclable;
  static const Color hazardous = wasteHazardous;
  static const Color general = wasteGeneral;

  // Status Colors
  static const Color pending = Color(0xFFFFA726); // Orange
  static const Color confirmed = Color(0xFF42A5F5); // Light Blue
  static const Color assigned = Color(0xFF7E57C2); // Purple
  static const Color inProgress = Color(0xFF26C6DA); // Cyan
  static const Color completed = Color(0xFF66BB6A); // Green
  static const Color cancelled = Color(0xFFEF5350); // Red

  // Neutral Colors
  static const Color black = Color(0xFF1A1A1A);
  static const Color darkGrey = Color(0xFF4A4A4A);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color white = Color(0xFFFFFFFF);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFAFAFA);

  // Semantic Colors
  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);

  // Text Colors
  static const Color text = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  static const Color disabled = Color(0xFFBDBDBD);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);

  /// Get color by waste type
  static Color getWasteTypeColor(String wasteType) {
    switch (wasteType.toLowerCase()) {
      case 'organic':
        return wasteOrganic;
      case 'recyclable':
        return wasteRecyclable;
      case 'hazardous':
        return wasteHazardous;
      case 'general':
        return wasteGeneral;
      case 'electronic':
        return wasteElectronic;
      default:
        return grey;
    }
  }

  /// Get color by status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pending;
      case 'confirmed':
        return confirmed;
      case 'assigned':
        return assigned;
      case 'in_progress':
      case 'in-progress':
        return inProgress;
      case 'completed':
        return completed;
      case 'cancelled':
        return cancelled;
      default:
        return grey;
    }
  }
}
