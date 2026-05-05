import 'package:hive/hive.dart';

// Salva i preferiti come lista di ID interi nel box 'settings' già aperto.
// Accesso sincrono garantito perché il box viene aperto in main.dart.
class FavoritesRepository {
  static const _boxName = 'settings';
  static const _key     = 'favorites';

  static Set<int> getAll() {
    final raw = Hive.box(_boxName).get(_key, defaultValue: <int>[]);
    return Set<int>.from(raw as List);
  }

  static Future<void> save(Set<int> ids) async {
    await Hive.box(_boxName).put(_key, ids.toList());
  }
}
