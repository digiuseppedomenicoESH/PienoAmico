import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/onboarding_repository.dart';

// true  → onboarding completato, mostra HomeScreen
// false → primo avvio, mostra OnboardingScreen
final onboardingCompletedProvider = StateProvider<bool>(
  (ref) => OnboardingRepository.isCompleted(),
);
