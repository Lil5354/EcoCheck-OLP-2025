import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service xử lý location & navigation - tách logic ra khỏi UI
class LocationService {
  /// Kiểm tra và request location permission
  static Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Lấy vị trí hiện tại
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Mở Google Maps để navigate
  static Future<void> navigateToLocation({
    required double destinationLat,
    required double destinationLng,
  }) async {
    try {
      final currentPosition = await getCurrentPosition();

      String url;
      if (currentPosition != null) {
        // Navigate từ vị trí hiện tại đến điểm đến
        url =
            'https://www.google.com/maps/dir/'
            '?api=1'
            '&origin=${currentPosition.latitude},${currentPosition.longitude}'
            '&destination=$destinationLat,$destinationLng'
            '&travelmode=driving';
      } else {
        // Chỉ mở điểm đến nếu không có vị trí hiện tại
        url =
            'https://www.google.com/maps/search/'
            '?api=1'
            '&query=$destinationLat,$destinationLng';
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Tính khoảng cách giữa 2 điểm (km)
  static double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) /
        1000; // Convert to km
  }
}
