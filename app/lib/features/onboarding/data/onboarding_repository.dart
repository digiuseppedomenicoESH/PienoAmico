import 'package:hive/hive.dart';

class OnboardingRepository {
  static const _boxName = 'settings';
  static const _keyCompleted = 'onboarding_completed';
  static const _keyCarburante = 'carburante_preferito';

  static bool isCompleted() =>
      (Hive.box(_boxName).get(_keyCompleted, defaultValue: false)) as bool;

  static Future<void> markCompleted() async =>
      Hive.box(_boxName).put(_keyCompleted, true);

  static String? getCarburantePreferito() =>
      Hive.box(_boxName).get(_keyCarburante) as String?;

  static Future<void> saveCarburantePreferito(String c) async =>
      Hive.box(_boxName).put(_keyCarburante, c);
}
