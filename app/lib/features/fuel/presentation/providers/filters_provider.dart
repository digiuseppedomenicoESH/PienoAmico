import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/filtri.dart';
import '../../../onboarding/data/onboarding_repository.dart';

class FiltriNotifier extends Notifier<Filtri> {
  @override
  Filtri build() {
    final saved = OnboardingRepository.getCarburantePreferito();
    if (saved != null && Filtri.carburantiDisponibili.contains(saved)) {
      return Filtri(carburante: saved);
    }
    return const Filtri();
  }

  void setCarburante(String carburante) =>
      state = state.copyWith(carburante: carburante);

  void setIsSelf(bool? isSelf) =>
      state = state.copyWith(isSelf: isSelf);

  void setRaggio(int raggioMetri) =>
      state = state.copyWith(raggioMetri: raggioMetri);

  void applyAll(Filtri filtri) => state = filtri;

  void reset() => state = const Filtri();
}

final filtriProvider = NotifierProvider<FiltriNotifier, Filtri>(FiltriNotifier.new);
