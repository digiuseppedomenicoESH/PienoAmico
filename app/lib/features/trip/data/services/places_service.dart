import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/trip_suggestion.dart';

class PlacesService {
  static const _baseUrl = 'https://places.googleapis.com/v1';

  Future<List<TripSuggestion>> autocomplete({
    required String input,
    double? nearLat,
    double? nearLon,
  }) async {
    if (input.trim().isEmpty) return [];

    final body = <String, dynamic>{
      'input': input,
      'includedRegionCodes': ['it'],
      'languageCode': 'it',
      if (nearLat != null && nearLon != null)
        'locationBias': {
          'circle': {
            'center': {'latitude': nearLat, 'longitude': nearLon},
            'radius': 100000.0,
          },
        },
    };

    final response = await http
        .post(
          Uri.parse('$_baseUrl/places:autocomplete'),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': AppConstants.googleMapsApiKey,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final suggestions = data['suggestions'] as List? ?? [];

    return suggestions.map((s) {
      final place = s['placePrediction'] as Map<String, dynamic>?;
      if (place == null) return null;
      final text = (place['text'] as Map<String, dynamic>?)?['text'] as String?;
      return TripSuggestion(
        placeId: place['placeId'] as String? ?? '',
        description: text ?? '',
      );
    }).whereType<TripSuggestion>().where((s) => s.placeId.isNotEmpty).toList();
  }

  Future<({double lat, double lon})?> getCoordinates(String placeId) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/places/$placeId?fields=location'),
          headers: {'X-Goog-Api-Key': AppConstants.googleMapsApiKey},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final location = data['location'] as Map<String, dynamic>?;
    if (location == null) return null;

    return (
      lat: (location['latitude'] as num).toDouble(),
      lon: (location['longitude'] as num).toDouble(),
    );
  }
}
