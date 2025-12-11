# Migration Guide: Google Maps to OpenStreetMap

## ✅ Completed Changes

### 1. Dependencies Updated

**EcoCheck_Worker/pubspec.yaml:**
```yaml
# OLD (Proprietary)
google_maps_flutter: ^2.5.3  # ❌ Removed

# NEW (100% Open Source)
flutter_map: ^7.0.2              # ✅ MIT License
flutter_map_tile_caching: ^10.0.2  # ✅ BSD-3 License
latlong2: ^0.9.1                 # ✅ Apache 2.0
```

**EcoCheck_User/pubspec.yaml:**
```yaml
# Added OpenStreetMap support
flutter_map: ^7.0.2
flutter_map_tile_caching: ^10.0.2
```

### 2. API Constants Updated

**Replaced:**
```dart
// OLD
static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

// NEW
static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
static const String osmAttribution = '© OpenStreetMap contributors';
static const String osmHotTileUrl = 'https://tile-a.openstreetmap.fr/hot/{z}/{x}/{y}.png';
static const String cartoLightTileUrl = 'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png';
```

---

## 🔄 Files That Need Manual Updates

### Files Using flutter_map (Already good - just verify):

1. **EcoCheck_Worker/lib/presentation/widgets/route/route_map_view.dart**
2. **EcoCheck_Worker/lib/presentation/screens/route_detail_screen.dart**

These files already use `flutter_map` which is open source. Just ensure they use the new OSM tile URLs.

### Example: How to Use OpenStreetMap with flutter_map

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/api_constants.dart';

class OpenStreetMapWidget extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  
  const OpenStreetMapWidget({
    Key? key,
    required this.center,
    this.zoom = 13.0,
    this.markers = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        // OpenStreetMap Tile Layer (100% Open Source)
        TileLayer(
          urlTemplate: ApiConstants.osmTileUrl,
          userAgentPackageName: 'com.ecocheck.worker',
          tileProvider: NetworkTileProvider(),
          maxZoom: 19,
          // Optional: Add attribution
          // subdomains: ['a', 'b', 'c'],
        ),
        
        // Markers Layer
        if (markers.isNotEmpty)
          MarkerLayer(markers: markers),
        
        // Attribution (Required by OSM)
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              ApiConstants.osmAttribution,
              onTap: () => launchUrl(
                Uri.parse('https://www.openstreetmap.org/copyright'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## 📦 Install New Dependencies

Run these commands in both apps:

```bash
# For EcoCheck_Worker
cd frontend-mobile/EcoCheck_Worker
flutter pub get
flutter pub upgrade

# For EcoCheck_User
cd ../EcoCheck_User
flutter pub get
flutter pub upgrade
```

---

## 🗺️ OpenStreetMap Tile Servers

### Primary (Default)
- **URL**: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- **License**: ODbL (Open Database License)
- **Attribution**: © OpenStreetMap contributors
- **Usage Policy**: Free for reasonable use, rate-limited

### Alternative Servers (For redundancy)

1. **Humanitarian OSM Style**
   - URL: `https://tile-a.openstreetmap.fr/hot/{z}/{x}/{y}.png`
   - Good for disaster relief visualization

2. **CartoDB Light**
   - URL: `https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png`
   - Clean, minimal style

3. **CartoDB Dark**
   - URL: `https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png`
   - Dark theme

---

## 🎨 Customization Options

### 1. Custom Markers

```dart
Marker(
  point: LatLng(10.7769, 106.7009),
  width: 40,
  height: 40,
  child: Icon(
    Icons.location_pin,
    color: Colors.red,
    size: 40,
  ),
)
```

### 2. Polylines (Routes)

```dart
PolylineLayer(
  polylines: [
    Polyline(
      points: routePoints, // List<LatLng>
      strokeWidth: 4.0,
      color: Colors.blue,
    ),
  ],
)
```

### 3. Circles (Radius)

```dart
CircleLayer(
  circles: [
    CircleMarker(
      point: LatLng(10.7769, 106.7009),
      radius: 100, // meters
      color: Colors.blue.withOpacity(0.3),
      borderStrokeWidth: 2,
      borderColor: Colors.blue,
    ),
  ],
)
```

---

## ⚡ Performance Tips

### 1. Enable Tile Caching

```dart
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

// Initialize caching
await FMTCObjectBoxBackend().initialise();

// Use cached tiles
TileLayer(
  urlTemplate: ApiConstants.osmTileUrl,
  tileProvider: FMTC.instance('mapStore').getTileProvider(),
)
```

### 2. Optimize for Mobile

```dart
MapOptions(
  initialCenter: center,
  initialZoom: 13.0,
  minZoom: 5.0,
  maxZoom: 18.0,
  // Performance optimizations
  interactionOptions: InteractionOptions(
    enableScrollWheel: true,
    enableMultiFingerGestureRace: true,
  ),
  // Reduce memory usage
  maxBounds: LatLngBounds(
    LatLng(southWestLat, southWestLng),
    LatLng(northEastLat, northEastLng),
  ),
)
```

---

## 🔒 License Compliance

### OpenStreetMap Data License
- **License**: ODbL (Open Database License)
- **Attribution Required**: Yes - "© OpenStreetMap contributors"
- **Commercial Use**: ✅ Allowed
- **Modification**: ✅ Allowed
- **Share-alike**: ✅ Required if you modify OSM data

### flutter_map Package
- **License**: BSD-3-Clause
- **Commercial Use**: ✅ Allowed
- **Attribution**: Not required but appreciated
- **MIT Compatible**: ✅ Yes

### Compliance Checklist
- [x] Include attribution: "© OpenStreetMap contributors"
- [x] Link to OSM copyright: https://www.openstreetmap.org/copyright
- [x] Use OSM Tile Usage Policy: https://operations.osmfoundation.org/policies/tiles/
- [x] Don't exceed rate limits (consider tile caching)

---

## 🚀 Next Steps

1. **Run `flutter pub get`** in both apps
2. **Verify map widgets** use OpenStreetMap tiles
3. **Test on devices** to ensure maps display correctly
4. **Remove Android/iOS Google Maps config** (if any)
5. **Update documentation** to mention OSM usage

---

## 📚 Resources

- **flutter_map Documentation**: https://docs.fleaflet.dev/
- **OpenStreetMap Tile Servers**: https://wiki.openstreetmap.org/wiki/Tile_servers
- **OSM Copyright**: https://www.openstreetmap.org/copyright
- **Tile Usage Policy**: https://operations.osmfoundation.org/policies/tiles/

---

## ✅ Benefits of This Migration

1. **100% Open Source**: No proprietary dependencies
2. **No API Keys**: No Google Maps API key required
3. **Cost-Free**: OpenStreetMap tiles are free
4. **Privacy-Friendly**: No tracking by Google
5. **License Compatible**: All packages are MIT/BSD/Apache compatible
6. **Community-Driven**: Supported by OSM community

---

**Migration Status**: ✅ Dependencies updated, ready for testing!

**Date**: December 11, 2025
