import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ClusterItem {
  final String id;
  final double lat;
  final double lng;
  final dynamic data;

  ClusterItem({
    required this.id,
    required this.lat,
    required this.lng,
    required this.data,
  });
}

class Cluster {
  final double lat;
  final double lng;
  final List<ClusterItem> items;

  Cluster({
    required this.lat,
    required this.lng,
    required this.items,
  });
}

class MapClusterEngine {
  static double _cellSize(double zoom) {
    if (zoom >= 17) return 0.0007;
    if (zoom >= 15) return 0.0012;
    if (zoom >= 13) return 0.0035;
    return 0.01;
  }

  static List<Cluster> clusterItems({
    required List<ClusterItem> items,
    required double zoom,
  }) {
    final Map<String, List<ClusterItem>> buckets = {};
    final cellSize = _cellSize(zoom);

    for (final item in items) {
      final gx = (item.lat / cellSize).floor();
      final gy = (item.lng / cellSize).floor();
      final key = "$gx:$gy";

      buckets.putIfAbsent(key, () => []);
      buckets[key]!.add(item);
    }

    final List<Cluster> clusters = [];

    buckets.forEach((_, bucket) {
      if (bucket.length == 1) {
        final i = bucket.first;
        clusters.add(
          Cluster(lat: i.lat, lng: i.lng, items: [i]),
        );
        return;
      }

      double avgLat = 0;
      double avgLng = 0;

      for (final i in bucket) {
        avgLat += i.lat;
        avgLng += i.lng;
      }

      avgLat /= bucket.length;
      avgLng /= bucket.length;

      clusters.add(
        Cluster(lat: avgLat, lng: avgLng, items: bucket),
      );
    });

    return clusters;
  }
}
