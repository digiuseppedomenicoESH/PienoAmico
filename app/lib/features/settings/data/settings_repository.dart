import 'package:hive/hive.dart';

// Persistenza preferenze utente (carburante default, raggio default).
class SettingsRepository {
  static const _boxName       = 'settings';
  static const _keyCarburante = 'carburante_default';
  static const _keyRaggio     = 'raggio_default';

  Future<Box> get _box async => Hive.openBox(_boxName);

  Future<String> getCarburanteDefault() async {
    final box = await _box;
    return (box.get(_keyCarburante) as String?) ?? 'benzina';
  }

  Future<void> setCarburanteDefault(String value) async {
    final box = await _box;
    await box.put(_keyCarburante, value);
  }

  Future<int> getRaggioDefault() async {
    final box = await _box;
    return (box.get(_keyRaggio) as int?) ?? 5000;
  }

  Future<void> setRaggioDefault(int value) async {
    final box = await _box;
    await box.put(_keyRaggio, value);
  }
}
