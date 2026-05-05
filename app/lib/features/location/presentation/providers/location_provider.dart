import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/location_service.dart';

final _locationServiceProvider = Provider((ref) => LocationService());

final locationProvider = FutureProvider<Position>((ref) {
  return ref.read(_locationServiceProvider).getCurrentPosition();
});
