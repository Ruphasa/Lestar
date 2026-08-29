import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/tokens.dart';

/// Satu penanda di peta. `payload` bebas — biasanya `NearbyListing` atau
/// `NearbyWaste`, dikembalikan apa adanya lewat `onMarkerTap`.
class LestarMapMarker {
  const LestarMapMarker({
    required this.point,
    required this.child,
    this.payload,
    this.width = 44,
    this.height = 44,
  });

  final LatLng point;
  final Widget child;
  final Object? payload;
  final double width;
  final double height;
}

/// Peta bersama. OpenStreetMap lewat `flutter_map` — tanpa API key, jadi
/// tidak ada kunci yang bisa bocor lewat APK.
///
/// **Tanda tangan dikunci.** D/E/F mengubah tampilan penanda lewat
/// `LestarMapMarker.child`, bukan dengan menambah parameter di sini.
class LestarMap extends StatelessWidget {
  const LestarMap({
    super.key,
    required this.center,
    this.zoom = 14,
    this.markers = const [],
    this.onMarkerTap,
    this.showUser = false,
    this.controller,
  });

  final LatLng center;
  final double zoom;
  final List<LestarMapMarker> markers;
  final void Function(LestarMapMarker)? onMarkerTap;

  /// Menggambar titik biru di [center]. Perizinan lokasi diminta layar
  /// pemanggil, bukan di sini.
  final bool showUser;

  final MapController? controller;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(initialCenter: center, initialZoom: zoom),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'id.lestar.lestar',
        ),
        if (showUser)
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 22,
                height: 22,
                child: const _TitikPengguna(),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final m in markers)
              Marker(
                point: m.point,
                width: m.width,
                height: m.height,
                child: onMarkerTap == null
                    ? m.child
                    : GestureDetector(
                        onTap: () => onMarkerTap!(m),
                        child: m.child,
                      ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TitikPengguna extends StatelessWidget {
  const _TitikPengguna();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: LestarTokens.emeraldDeep,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
    ),
  );
}
