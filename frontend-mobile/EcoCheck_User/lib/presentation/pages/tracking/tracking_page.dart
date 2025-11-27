import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();

  // Mock data
  bool _isVehicleNearby = true;
  int _estimatedArrivalMinutes = 15;
  String _vehicleId = "XE-001";
  String _vehicleType = "Rác sinh hoạt";

  // Air quality mock data (from weather/environment API)
  int _aqi = 85; // Air Quality Index
  String _aqiLevel = "Trung bình";
  Color _aqiColor = AppColors.warning;

  // Camera position - HCMC center
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(10.762622, 106.660172), // HCMC coordinates
    zoom: 14.5,
  );

  // Mock vehicle location (moving)
  LatLng _vehicleLocation = const LatLng(10.770000, 106.670000);

  // User location
  final LatLng _userLocation = const LatLng(10.762622, 106.660172);

  // Markers
  final Set<Marker> _markers = {};

  // Polylines for route
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _setupMarkersAndRoute();
  }

  void _setupMarkersAndRoute() {
    // User marker
    _markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: _userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'Vị trí của bạn',
          snippet: '123 Nguyễn Huệ, Q1',
        ),
      ),
    );

    // Vehicle marker
    _markers.add(
      Marker(
        markerId: const MarkerId('vehicle'),
        position: _vehicleLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: _vehicleId, snippet: _vehicleType),
      ),
    );

    // Route polyline
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_vehicleLocation, _userLocation],
        color: AppColors.primary,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );

    // Simulate vehicle movement
    _startVehicleMovement();
  }

  void _startVehicleMovement() {
    // Simulate vehicle moving every 3 seconds
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Move vehicle closer to user
        _vehicleLocation = LatLng(
          _vehicleLocation.latitude +
              (_userLocation.latitude - _vehicleLocation.latitude) * 0.1,
          _vehicleLocation.longitude +
              (_userLocation.longitude - _vehicleLocation.longitude) * 0.1,
        );

        // Update vehicle marker
        _markers.removeWhere((m) => m.markerId.value == 'vehicle');
        _markers.add(
          Marker(
            markerId: const MarkerId('vehicle'),
            position: _vehicleLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(title: _vehicleId, snippet: _vehicleType),
          ),
        );

        // Update polyline
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [_vehicleLocation, _userLocation],
            color: AppColors.primary,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );

        // Update ETA (decrease by 1 minute)
        if (_estimatedArrivalMinutes > 0) {
          _estimatedArrivalMinutes--;
        }
      });
    });
  }

  Future<void> _goToVehicle() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _vehicleLocation, zoom: 16, tilt: 45),
      ),
    );
  }

  Future<void> _goToUser() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _userLocation, zoom: 16, tilt: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi xe rác'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToUser,
            tooltip: 'Vị trí của tôi',
          ),
          IconButton(
            icon: const Icon(Icons.local_shipping),
            onPressed: _goToVehicle,
            tooltip: 'Vị trí xe rác',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Air Quality Index Card (Top)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _AirQualityCard(
              aqi: _aqi,
              level: _aqiLevel,
              color: _aqiColor,
            ),
          ),

          // Vehicle Info Card (Bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _VehicleInfoCard(
              isNearby: _isVehicleNearby,
              vehicleId: _vehicleId,
              vehicleType: _vehicleType,
              estimatedMinutes: _estimatedArrivalMinutes,
            ),
          ),
        ],
      ),
    );
  }
}

/// Air Quality Index Card
class _AirQualityCard extends StatelessWidget {
  final int aqi;
  final String level;
  final Color color;

  const _AirQualityCard({
    required this.aqi,
    required this.level,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.air, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chất lượng không khí', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        aqi.toString(),
                        style: AppTextStyles.h3.copyWith(color: color),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AQI',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      level,
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.info_outline, color: AppColors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Vehicle Info Card
class _VehicleInfoCard extends StatelessWidget {
  final bool isNearby;
  final String vehicleId;
  final String vehicleType;
  final int estimatedMinutes;

  const _VehicleInfoCard({
    required this.isNearby,
    required this.vehicleId,
    required this.vehicleType,
    required this.estimatedMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status banner
                if (isNearby)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active,
                          color: AppColors.success,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xe đang đến gần!',
                                style: AppTextStyles.h5.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dự kiến: $estimatedMinutes phút nữa',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Vehicle info
                Text('Thông tin xe', style: AppTextStyles.h5),

                const SizedBox(height: 12),

                _InfoRow(
                  icon: Icons.local_shipping,
                  label: 'Mã xe',
                  value: vehicleId,
                ),

                const SizedBox(height: 12),

                _InfoRow(
                  icon: Icons.delete_outline,
                  label: 'Loại xe',
                  value: vehicleType,
                ),

                const SizedBox(height: 12),

                _InfoRow(icon: Icons.speed, label: 'Tốc độ', value: '25 km/h'),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Call driver
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đang gọi lái xe...')),
                          );
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Gọi lái xe'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Show route details
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Xem chi tiết lộ trình'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.route),
                        label: const Text('Lộ trình'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.grey),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
