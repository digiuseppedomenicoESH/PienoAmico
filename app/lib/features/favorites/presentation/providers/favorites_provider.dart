import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/favorites_repository.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<int>>(
  (ref) => FavoritesNotifier(),
);

class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier() : super(FavoritesRepository.getAll());

  bool isFavorite(int id) => state.contains(id);

  void toggle(int id) {
    final next = Set<int>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    FavoritesRepository.save(next);
  }
}
