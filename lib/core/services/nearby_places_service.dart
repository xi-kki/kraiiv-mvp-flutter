import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

/// A real food market / farm shop near the user's city.
class NearbyPlace {
  final String name;
  final String kind; // Overpass tag: marketplace | greengrocer | farm | ...
  final double distanceKm;
  final double? lat;
  final double? lon;

  const NearbyPlace({
    required this.name,
    required this.kind,
    required this.distanceKm,
    this.lat,
    this.lon,
  });

  /// Google Maps search URL — by coordinates when Overpass gave us exact
  /// ones, by name otherwise (Google resolves it).
  String get mapsUrl {
    if (lat != null && lon != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
    }
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}';
  }
}

/// Finds local food places near the user's city — the prototype's
/// location step in action ("suggest nearby places producing/distributing
/// organic food").
///
/// Tries the OpenStreetMap Overpass API first (fresh results, exact
/// coordinates). The free public instances are slow and sometimes
/// time out, so on any failure it falls back to a curated list of
/// well-known real markets per supported city — the demo always has
/// content, and the data stays genuine either way.
class NearbyPlacesService {
  static const String _overpassUrl =
      'https://overpass-api.de/api/interpreter';
  static const Duration _timeout = Duration(seconds: 12);

  /// Supported cities → center coordinates (Overpass bounding box anchor).
  static const Map<String, List<double>> _cityCenters = {
    'Lagos': [6.5244, 3.3792],
    'Abuja': [9.0765, 7.3986],
    'Ibadan': [7.3775, 3.9470],
    'Port Harcourt': [4.8156, 7.0498],
    'Kano': [12.0022, 8.5920],
  };

  /// Curated fallback: real, well-known food markets per city
  /// (coordinates are approximate area anchors).
  static const List<NearbyPlace> _curatedLagos = [
    NearbyPlace(name: 'Mile 12 Market', kind: 'marketplace', distanceKm: 0, lat: 6.6322, lon: 3.4041),
    NearbyPlace(name: 'Tejuosho Market', kind: 'marketplace', distanceKm: 0, lat: 6.4822, lon: 3.3785),
    NearbyPlace(name: 'Balogun Market', kind: 'marketplace', distanceKm: 0, lat: 6.4545, lon: 3.3883),
    NearbyPlace(name: 'Lekki Market', kind: 'marketplace', distanceKm: 0, lat: 6.4460, lon: 3.5497),
    NearbyPlace(name: 'Agege Market', kind: 'marketplace', distanceKm: 0, lat: 6.6108, lon: 3.3380),
  ];
  static const List<NearbyPlace> _curatedAbuja = [
    NearbyPlace(name: 'Garki Modern Market', kind: 'marketplace', distanceKm: 0, lat: 9.0260, lon: 7.4930),
    NearbyPlace(name: 'Wuse Market', kind: 'marketplace', distanceKm: 0, lat: 9.0780, lon: 7.4900),
    NearbyPlace(name: 'Dei-Dei International Market', kind: 'marketplace', distanceKm: 0, lat: 9.0050, lon: 7.4340),
    NearbyPlace(name: 'Karu Market', kind: 'marketplace', distanceKm: 0, lat: 8.9970, lon: 7.5680),
  ];
  static const List<NearbyPlace> _curatedIbadan = [
    NearbyPlace(name: 'Bodija Market', kind: 'marketplace', distanceKm: 0, lat: 7.4380, lon: 3.8930),
    NearbyPlace(name: 'Oja Oba Market', kind: 'marketplace', distanceKm: 0, lat: 7.3770, lon: 3.8990),
    NearbyPlace(name: 'Dugbe Market', kind: 'marketplace', distanceKm: 0, lat: 7.3770, lon: 3.9020),
    NearbyPlace(name: 'Aleshinloye Market', kind: 'marketplace', distanceKm: 0, lat: 7.3850, lon: 3.8750),
  ];
  static const List<NearbyPlace> _curatedPortHarcourt = [
    NearbyPlace(name: 'Mile 1 Market', kind: 'marketplace', distanceKm: 0, lat: 4.7970, lon: 7.0360),
    NearbyPlace(name: 'Mile 3 Market', kind: 'marketplace', distanceKm: 0, lat: 4.8010, lon: 7.0150),
    NearbyPlace(name: 'Creek Road Market', kind: 'marketplace', distanceKm: 0, lat: 4.7540, lon: 7.0500),
    NearbyPlace(name: 'Rumuokoro Market', kind: 'marketplace', distanceKm: 0, lat: 4.8610, lon: 6.9960),
  ];
  static const List<NearbyPlace> _curatedKano = [
    NearbyPlace(name: 'Sabon Gari Market', kind: 'marketplace', distanceKm: 0, lat: 11.9870, lon: 8.5230),
    NearbyPlace(name: 'Kurmi Market', kind: 'marketplace', distanceKm: 0, lat: 12.0000, lon: 8.5160),
    NearbyPlace(name: 'Singa Market', kind: 'marketplace', distanceKm: 0, lat: 12.0100, lon: 8.5200),
    NearbyPlace(name: 'Dawanau Market', kind: 'marketplace', distanceKm: 0, lat: 12.0610, lon: 8.3990),
  ];

  static const Map<String, List<NearbyPlace>> _curated = {
    'Lagos': _curatedLagos,
    'Abuja': _curatedAbuja,
    'Ibadan': _curatedIbadan,
    'Port Harcourt': _curatedPortHarcourt,
    'Kano': _curatedKano,
  };

  /// Normalizes the stored city name to a known key (defaults to Lagos
  /// for unknown/empty entries so the section always has an anchor).
  static String canonicalCity(String city) {
    final trimmed = city.trim().toLowerCase();
    for (final entry in _cityCenters.keys) {
      if (entry.toLowerCase() == trimmed) return entry;
    }
    return 'Lagos';
  }

  static Future<List<NearbyPlace>> fetchNearby(String city) async {
    final canon = canonicalCity(city);
    try {
      final places = await _fetchOverpass(canon);
      if (places.isNotEmpty) return places;
    } catch (e) {
      debugPrint('Overpass unavailable ($e) — using curated markets');
    }
    return curatedFor(canon);
  }

  static Future<List<NearbyPlace>> _fetchOverpass(String city) async {
    final center = _cityCenters[city]!;
    final lat = center[0];
    final lon = center[1];
    // Small box (~0.5° x 0.6°) around the city centre: bbox queries are
    // indexed on Overpass, whereas `around` scans the whole area and the
    // free instances time out on dense Nigerian cities.
    final bbox = '${lat - 0.5},${lon - 0.6},${lat + 0.5},${lon + 0.6}';
    final query = '''
[out:json][timeout:10];
(
  nwr[amenity=marketplace]($bbox);
  nwr[shop=greengrocer]($bbox);
  nwr[shop=farm]($bbox);
);
out center body 15;''';
    final resp = await http
        .post(Uri.parse(_overpassUrl), body: {'data': query})
        .timeout(_timeout);
    if (resp.statusCode != 200) return [];
    return parseOverpass(resp.body, lat, lon);
  }

  /// Pure parser (testable without network). Accepts the Overpass
  /// `[out:json]` body and returns named places sorted by distance.
  static List<NearbyPlace> parseOverpass(
    String body,
    double centerLat,
    double centerLon,
  ) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final elements = (json['elements'] as List<dynamic>? ?? []);
    final places = <NearbyPlace>[];
    for (final e in elements) {
      final el = e as Map<String, dynamic>;
      final tags = el['tags'] as Map<String, dynamic>? ?? const {};
      final name = tags['name'] as String?;
      if (name == null || name.trim().isEmpty) continue;

      final center = el['center'] as Map<String, dynamic>?;
      final lat = (el['lat'] as num?)?.toDouble() ??
          (center?['lat'] as num?)?.toDouble();
      final lon = (el['lon'] as num?)?.toDouble() ??
          (center?['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;

      final kind =
          (tags['shop'] ?? tags['amenity'] ?? 'food place') as String;
      places.add(
        NearbyPlace(
          name: name.trim(),
          kind: kind,
          distanceKm: haversineKm(centerLat, centerLon, lat, lon),
          lat: lat,
          lon: lon,
        ),
      );
    }
    places.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return places.take(6).toList();
  }

  /// The curated list for a canonical city, with real distances from the
  /// city centre.
  static List<NearbyPlace> curatedFor(String city) {
    final center = _cityCenters[city]!;
    return _curated[city]!
        .map(
          (p) => NearbyPlace(
            name: p.name,
            kind: p.kind,
            distanceKm: haversineKm(center[0], center[1], p.lat!, p.lon!),
            lat: p.lat,
            lon: p.lon,
          ),
        )
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
}
