import '../../domain/entities/trip_result.dart';
import '../../domain/entities/trip_suggestion.dart';
import '../datasources/trip_remote_datasource.dart';
import '../services/places_service.dart';
import '../services/routes_service.dart';

class TripRepository {
  final PlacesService _places;
  final RoutesService _routes;
  final TripRemoteDatasource _datasource;

  TripRepository(this._places, this._routes, this._datasource);

  Future<List<TripSuggestion>> searchDestination(
    String input, {
    double? nearLat,
    double? nearLon,
  }) =>
      _places.autocomplete(input: input, nearLat: nearLat, nearLon: nearLon);

  Future<TripResult?> planTrip({
    required double originLat,
    required double originLon,
    required String destinationPlaceId,
    required String carburante,
  }) async {
    final dest = await _places.getCoordinates(destinationPlaceId);
    if (dest == null) return null;

    final routePoints = await _routes.computeRoute(
      originLat: originLat,
      originLon: originLon,
      destLat: dest.lat,
      destLon: dest.lon,
    );
    if (routePoints == null || routePoints.isEmpty) {
      throw Exception('Nessun percorso trovato tra origine e destinazione');
    }

    final stations = await _datasource.getFuelAlongRoute(
      routePoints: routePoints,
      carburante: carburante,
    );

    return TripResult(routePoints: routePoints, stations: stations);
  }
}
