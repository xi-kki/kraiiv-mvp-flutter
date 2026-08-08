import 'package:flutter_test/flutter_test.dart';
import 'package:kraiiv/core/services/nearby_places_service.dart';

void main() {
  group('NearbyPlacesService.parseOverpass', () {
    test('parses nodes with lat/lon and sorts by distance', () {
      const body = '''
{
  "elements": [
    {"type": "node", "id": 1, "lat": 6.45, "lon": 3.39,
     "tags": {"name": "Far Market", "amenity": "marketplace"}},
    {"type": "node", "id": 2, "lat": 6.52, "lon": 3.38,
     "tags": {"name": "Near Farm", "shop": "farm"}}
  ]
}
''';
      final places = NearbyPlacesService.parseOverpass(body, 6.52, 3.38);

      expect(places, hasLength(2));
      // Sorted nearest first: Near Farm is at the centre, Far Market ~8km.
      expect(places.first.name, 'Near Farm');
      expect(places.first.kind, 'farm');
      expect(places.first.distanceKm, lessThan(1));
      expect(places.last.name, 'Far Market');
      expect(places.last.kind, 'marketplace');
      expect(places.last.distanceKm, greaterThan(5));
      // Overpass results carry exact coordinates → maps link uses them.
      expect(places.first.mapsUrl, contains('query=6.52,3.38'));
    });

    test('reads lat/lon from way "center" objects', () {
      const body = '''
{
  "elements": [
    {"type": "way", "id": 3,
     "center": {"lat": 6.50, "lon": 3.40},
     "tags": {"name": "Big Market", "amenity": "marketplace"}}
  ]
}
''';
      final places = NearbyPlacesService.parseOverpass(body, 6.50, 3.40);

      expect(places, hasLength(1));
      expect(places.single.name, 'Big Market');
      expect(places.single.distanceKm, lessThan(1));
    });

    test('drops unnamed and unlocated elements', () {
      const body = '''
{
  "elements": [
    {"type": "node", "id": 4, "lat": 6.5, "lon": 3.4,
     "tags": {"amenity": "marketplace"}},
    {"type": "node", "id": 5,
     "tags": {"name": "No Coords Here"}},
    {"type": "node", "id": 6, "lat": 6.5, "lon": 3.4,
     "tags": {"name": "Good One", "shop": "greengrocer"}}
  ]
}
''';
      final places = NearbyPlacesService.parseOverpass(body, 6.5, 3.4);

      expect(places, hasLength(1));
      expect(places.single.name, 'Good One');
    });
  });

  group('NearbyPlacesService curated fallback', () {
    test('canonicalCity maps known names and defaults to Lagos', () {
      expect(NearbyPlacesService.canonicalCity('lagos'), 'Lagos');
      expect(NearbyPlacesService.canonicalCity(' Port Harcourt '), 'Port Harcourt');
      expect(NearbyPlacesService.canonicalCity('Somewhere Else'), 'Lagos');
      expect(NearbyPlacesService.canonicalCity(''), 'Lagos');
    });

    test('curatedFor returns real markets with positive distances', () {
      final places = NearbyPlacesService.curatedFor('Lagos');

      expect(places, isNotEmpty);
      for (final place in places) {
        expect(place.name, isNotEmpty);
        expect(place.kind, 'marketplace');
        expect(place.distanceKm, greaterThanOrEqualTo(0));
        expect(place.mapsUrl, contains('www.google.com/maps'));
      }
      // Sorted nearest-first.
      for (var i = 1; i < places.length; i++) {
        expect(
          places[i].distanceKm,
          greaterThanOrEqualTo(places[i - 1].distanceKm),
        );
      }
    });
  });
}
