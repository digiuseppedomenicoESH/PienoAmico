import 'package:hive/hive.dart';

// Legge e scrive il flag di completamento onboarding.
// Usa il box 'settings' già aperto in main.dart — accesso sincrono garantito.
class OnboardingRepository {
  static const _boxName = 'settings';
  static const _key     = 'onboarding_completed';

  static bool isCompleted() {
    return (Hive.box(_boxName).get(_key, defaultValue: false)) as bool;
  }

  static Future<void> markCompleted() async {
    await Hive.box(_boxName).put(_key, true);
  }
}
