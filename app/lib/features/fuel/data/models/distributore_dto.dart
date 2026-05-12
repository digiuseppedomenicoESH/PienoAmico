import '../../domain/entities/distributore.dart';

// DTO: responsabile SOLO di serializzare/deserializzare JSON Supabase.
// Non contiene logica di dominio.
class DistributoreDto {
  static Distributore fromJson(Map<String, dynamic> json) {
    return Distributore(
      id:              json['id'] as int,
      nome:            (json['nome']      as String?) ?? '',
      bandiera:        (json['bandiera']  as String?) ?? '',
      indirizzo:       (json['indirizzo'] as String?) ?? '',
      comune:          (json['comune']    as String?) ?? '',
      isAutostradale:  (json['tipo_impianto'] as String?) == 'autostradale',
      latitudine:      (json['latitudine']  as num).toDouble(),
      longitudine:     (json['longitudine'] as num).toDouble(),
      distanzaM:       (json['distanza_m']  as num).toInt(),
      deviazioneM:     (json['deviazione_m'] as num?)?.toInt(),
      prezzoSelf:      (json['prezzo_self']    as num?)?.toDouble(),
      prezzoServito:   (json['prezzo_servito'] as num?)?.toDouble(),
      dtAggiornamento: json['dt_aggiornamento'] != null
          ? DateTime.parse(json['dt_aggiornamento'] as String)
          : null,
    );
  }
}
