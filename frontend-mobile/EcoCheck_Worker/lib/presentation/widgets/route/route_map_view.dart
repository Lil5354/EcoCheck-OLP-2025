import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/worker_route.dart';

/// Widget hiển thị Google Maps - tách ra để dễ quản lý
class RouteMapView extends StatefulWidget {
  final WorkerRoute route;
  final int? selectedPointIndex;
  final Function(GoogleMapController) onMapCreated;

  const RouteMapView({
    super.key,
    required this.route,
    this.selectedPointIndex,
    required this.onMapCreated,
  });

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeMapData();
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
    _markers.clear();
    _polylines.clear();

    // Create markers for each point
    for (int i = 0; i < widget.route.points.length; i++) {
      final point = widget.route.points[i];
      final isSelected = i == widget.selectedPointIndex;

      _markers.add(
        Marker(
          markerId: MarkerId(point.id),
          position: LatLng(point.latitude, point.longitude),
          icon: _getMarkerIcon(point.status, isSelected),
          infoWindow: InfoWindow(
            title: 'Điểm ${i + 1}',
            snippet: point.address,
          ),
        ),
      );
    }

    // Create polyline connecting all points
    if (widget.route.points.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_polyline'),
          points: widget.route.points
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList(),
          color: Colors.green,
          width: 4,
        ),
      );
    }

    if (mounted) setState(() {});
  }

  BitmapDescriptor _getMarkerIcon(String status, bool isSelected) {
    // TODO: Use custom marker icons
    return BitmapDescriptor.defaultMarkerWithHue(
      status == 'collected'
          ? BitmapDescriptor.hueGreen
          : status == 'skipped'
          ? BitmapDescriptor.hueRed
          : BitmapDescriptor.hueOrange,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.route.points.isEmpty) {
      return const Center(child: Text('Không có điểm thu gom'));
    }

    final firstPoint = widget.route.points.first;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(firstPoint.latitude, firstPoint.longitude),
        zoom: 14,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      onMapCreated: widget.onMapCreated,
    );
  }
}
