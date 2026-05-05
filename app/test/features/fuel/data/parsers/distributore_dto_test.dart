import 'package:flutter_test/flutter_test.dart';
import 'package:pienoamico/features/fuel/data/models/distributore_dto.dart';

void main() {
  group('DistributoreDto.fromJson', () {
    final json = {
      'id': 1001,
      'nome': 'Eni Loreto',
      'bandiera': 'Agip Eni',
      'indirizzo': 'Viale Monza 1',
      'comune': 'Milano',
      'tipo_impianto': 'stradale',
      'latitudine': 45.482,
      'longitudine': 9.220,
      'distanza_m': 843,
      'prezzo_self': 1.659,
      'prezzo_servito': 1.759,
      'dt_aggiornamento': '2026-05-05T08:15:32+00:00',
    };

    test('deserializza correttamente tutti i campi', () {
      final d = DistributoreDto.fromJson(json);
      expect(d.id, 1001);
      expect(d.nome, 'Eni Loreto');
      expect(d.prezzoSelf, 1.659);
      expect(d.prezzoServito, 1.759);
      expect(d.isAutostradale, false);
      expect(d.dtAggiornamento, isNotNull);
    });

    test('prezzoBest restituisce self se disponibile', () {
      final d = DistributoreDto.fromJson(json);
      expect(d.prezzoBest, 1.659);
    });

    test('prezzoBest restituisce servito se self è null', () {
      final jsonSenzaSelf = Map<String, dynamic>.from(json)
        ..['prezzo_self'] = null;
      final d = DistributoreDto.fromJson(jsonSenzaSelf);
      expect(d.prezzoBest, 1.759);
    });

    test('gestisce dt_aggiornamento null', () {
      final jsonSenzaData = Map<String, dynamic>.from(json)
        ..['dt_aggiornamento'] = null;
      final d = DistributoreDto.fromJson(jsonSenzaData);
      expect(d.dtAggiornamento, isNull);
      expect(d.isPrezzoFresco, false);
    });
  });
}
