import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/worker_route.dart';

/// Widget hiển thị OpenStreetMap - tách ra để dễ quản lý
class RouteMapView extends StatefulWidget {
  final WorkerRoute route;
  final int? selectedPointIndex;
  final Function(MapController)? onMapCreated;

  const RouteMapView({
    super.key,
    required this.route,
    this.selectedPointIndex,
    this.onMapCreated,
  });

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _initializeMapData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMapCreated?.call(_mapController);
    });
  }

  @override
  void didUpdateWidget(RouteMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route != widget.route ||
        oldWidget.selectedPointIndex != widget.selectedPointIndex) {
      _initializeMapData();
    }
  }

  void _initializeMapData() {
    _markers = [];
    _polylines = [];

    if (widget.route.points.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    // Add START marker from depot (if available)
    if (widget.route.depotLat != null && widget.route.depotLon != null) {
      _markers.add(
        Marker(
          point: LatLng(widget.route.depotLat!, widget.route.depotLon!),
          width: 50,
          height: 70,
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'START',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Add END marker from dump (if available)
    if (widget.route.dumpLat != null && widget.route.dumpLon != null) {
      _markers.add(
        Marker(
          point: LatLng(widget.route.dumpLat!, widget.route.dumpLon!),
          width: 50,
          height: 70,
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'END',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Create markers for each collection point
    for (int i = 0; i < widget.route.points.length; i++) {
      final point = widget.route.points[i];

      _markers.add(
        Marker(
          point: LatLng(point.latitude, point.longitude),
          width: 45,
          height: 45,
          child: GestureDetector(
            child: Container(
              decoration: BoxDecoration(
                color: _getMarkerColor(point.status),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Create polylines with different colors for completed/pending segments
    List<LatLng> allPoints = [];

    // Start from depot
    if (widget.route.depotLat != null && widget.route.depotLon != null) {
      allPoints.add(LatLng(widget.route.depotLat!, widget.route.depotLon!));
    }

    // Add all collection points
    for (var point in widget.route.points) {
      allPoints.add(LatLng(point.latitude, point.longitude));
    }

    // End at dump
    if (widget.route.dumpLat != null && widget.route.dumpLon != null) {
      allPoints.add(LatLng(widget.route.dumpLat!, widget.route.dumpLon!));
    }

    // Create colored segments based on completion status
    if (allPoints.length > 1) {
      int startOffset =
          (widget.route.depotLat != null && widget.route.depotLon != null)
          ? 1
          : 0;

      for (int i = 0; i < allPoints.length - 1; i++) {
        Color segmentColor;

        // Determine segment color based on point status
        if (i == 0 && startOffset == 1) {
          // Depot to first point - always blue (starting)
          segmentColor = const Color(0xFF2196F3);
        } else {
          int pointIndex = i - startOffset;
          if (pointIndex >= 0 && pointIndex < widget.route.points.length) {
            final point = widget.route.points[pointIndex];
            if (point.status == 'completed' || point.status == 'collected') {
              segmentColor = AppColors.completed; // Green for completed
            } else if (point.status == 'skipped') {
              segmentColor = AppColors.cancelled; // Red for skipped
            } else {
              segmentColor = const Color(0xFF2196F3); // Blue for pending
            }
          } else {
            segmentColor = const Color(0xFF2196F3);
          }
        }

        _polylines.add(
          Polyline(
            points: [allPoints[i], allPoints[i + 1]],
            color: segmentColor,
            strokeWidth: 6.0,
            borderColor: Colors.white,
            borderStrokeWidth: 2.0,
          ),
        );
      }
    }

    if (mounted) setState(() {});
  }

  Color _getMarkerColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.completed;
      case 'skipped':
        return AppColors.error;
      case 'pending':
      default:
        return const Color(0xFFFFA726); // Orange/Yellow color like web
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use depot location as center if available, otherwise first collection point
    LatLng center;
    if (widget.route.depotLat != null && widget.route.depotLon != null) {
      center = LatLng(widget.route.depotLat!, widget.route.depotLon!);
    } else if (widget.route.points.isNotEmpty) {
      final firstPoint = widget.route.points.first;
      center = LatLng(firstPoint.latitude, firstPoint.longitude);
    } else {
      // Default to HCM City center
      center = const LatLng(10.7769, 106.6958);
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12.0,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ecocheck.worker',
          maxZoom: 19,
        ),
        PolylineLayer(polylines: _polylines),
        MarkerLayer(markers: _markers),
      ],
    );
  }
}
