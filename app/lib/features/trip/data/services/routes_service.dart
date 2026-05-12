import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';

class RoutesService {
  static const _url =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  Future<List<LatLng>?> computeRoute({
    required double originLat,
    required double originLon,
    required double destLat,
    required double destLon,
  }) async {
    final body = {
      'origin': {
        'location': {
          'latLng': {'latitude': originLat, 'longitude': originLon},
        },
      },
      'destination': {
        'location': {
          'latLng': {'latitude': destLat, 'longitude': destLon},
        },
      },
      'travelMode': 'DRIVE',
      'routingPreference': 'TRAFFIC_UNAWARE',
    };

    final response = await http
        .post(
          Uri.parse(_url),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': AppConstants.googleMapsApiKey,
            'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) return null;

    final encoded =
        (routes[0] as Map<String, dynamic>)['polyline']?['encodedPolyline']
            as String?;
    if (encoded == null) return null;

    return _decodePolyline(encoded);
  }

  // Algoritmo standard Google Encoded Polyline
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    final len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
