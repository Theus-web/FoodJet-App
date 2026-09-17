import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  final LatLng? position;

  const MapWidget({
    super.key,
    this.position,
  });

  @override
  Widget build(BuildContext context) {
    final center = position ?? const LatLng(-19.4708, -42.5396);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: center,
          zoom: 15,
        ),
        myLocationEnabled: position != null,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }
}
