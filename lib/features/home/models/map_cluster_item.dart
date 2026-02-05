import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapClusterItem {
  final String id;
  final String title;
  final double lat;
  final double lng;
  final int missingPlayers;

  const MapClusterItem({
    required this.id,
    required this.title,
    required this.lat,
    required this.lng,
    required this.missingPlayers,
  });

  LatLng get position => LatLng(lat, lng);
}
