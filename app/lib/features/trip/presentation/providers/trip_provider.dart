import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/trip_remote_datasource.dart';
import '../../data/repositories/trip_repository.dart';
import '../../data/services/places_service.dart';
import '../../data/services/routes_service.dart';
import '../../domain/entities/trip_result.dart';
import '../../domain/entities/trip_suggestion.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../fuel/presentation/providers/filters_provider.dart';

// ── Repository singleton ─────────────────────────────────────

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(
    PlacesService(),
    RoutesService(),
    TripRemoteDatasource(Supabase.instance.client),
  );
});

// ── Input dell'utente (testo campo ricerca) ──────────────────

final tripInputProvider = StateProvider<String>((ref) => '');

// ── Suggerimenti autocomplete ────────────────────────────────

final tripSuggestionsProvider =
    FutureProvider<List<TripSuggestion>>((ref) async {
  final input = ref.watch(tripInputProvider);
  if (input.trim().length < 2) return [];

  final locationAsync = ref.watch(locationProvider);
  final pos = locationAsync.valueOrNull;

  return ref.read(tripRepositoryProvider).searchDestination(
        input,
        nearLat: pos?.latitude,
        nearLon: pos?.longitude,
      );
});

// ── Destinazione selezionata ─────────────────────────────────

final tripSelectedProvider = StateProvider<TripSuggestion?>((ref) => null);

// ── Risultato pianificazione (route + stazioni) ──────────────

final tripResultProvider = FutureProvider<TripResult?>((ref) async {
  final selected = ref.watch(tripSelectedProvider);
  if (selected == null) return null;

  final locationAsync = await ref.watch(locationProvider.future);
  final carburante = ref.watch(filtriProvider).carburante;

  return ref.read(tripRepositoryProvider).planTrip(
        originLat: locationAsync.latitude,
        originLon: locationAsync.longitude,
        destinationPlaceId: selected.placeId,
        carburante: carburante,
      );
});
