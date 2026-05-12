// Entity del dominio. Nessuna dipendenza da Flutter o da Supabase.

class Distributore {
  final int id;
  final String nome;
  final String bandiera;
  final String indirizzo;
  final String comune;
  final bool isAutostradale;
  final double latitudine;
  final double longitudine;
  final int distanzaM;
  final int? deviazioneM;
  final double? prezzoSelf;
  final double? prezzoServito;
  final DateTime? dtAggiornamento;

  const Distributore({
    required this.id,
    required this.nome,
    required this.bandiera,
    required this.indirizzo,
    required this.comune,
    required this.isAutostradale,
    required this.latitudine,
    required this.longitudine,
    required this.distanzaM,
    this.deviazioneM,
    this.prezzoSelf,
    this.prezzoServito,
    this.dtAggiornamento,
  });

  double? get prezzoBest => prezzoSelf ?? prezzoServito;

  bool get isPrezzoFresco {
    if (dtAggiornamento == null) return false;
    return DateTime.now().difference(dtAggiornamento!).inHours < 48;
  }
}
