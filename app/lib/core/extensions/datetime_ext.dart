extension DateTimeExt on DateTime {
  // "Aggiornato 2h fa" / "Aggiornato ieri" / "Aggiornato 3 giorni fa"
  String get asAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 60)  return 'Aggiornato ${diff.inMinutes} min fa';
    if (diff.inHours < 24)    return 'Aggiornato ${diff.inHours}h fa';
    if (diff.inDays == 1)     return 'Aggiornato ieri';
    return 'Aggiornato ${diff.inDays} giorni fa';
  }

  bool get isOlderThan48h => DateTime.now().difference(this).inHours > 48;
}
