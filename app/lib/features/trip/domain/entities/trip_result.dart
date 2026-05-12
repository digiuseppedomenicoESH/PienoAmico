import 'package:latlong2/latlong.dart';
import '../../../fuel/domain/entities/distributore.dart';

class TripResult {
  final List<LatLng> routePoints;
  final List<Distributore> stations;

  const TripResult({required this.routePoints, required this.stations});
}
