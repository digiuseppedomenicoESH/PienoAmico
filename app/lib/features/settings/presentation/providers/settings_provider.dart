import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/settings_repository.dart';

final _settingsRepoProvider = Provider((ref) => SettingsRepository());

final carburanteDefaultProvider = FutureProvider<String>((ref) {
  return ref.read(_settingsRepoProvider).getCarburanteDefault();
});

final raggioDefaultProvider = FutureProvider<int>((ref) {
  return ref.read(_settingsRepoProvider).getRaggioDefault();
});
