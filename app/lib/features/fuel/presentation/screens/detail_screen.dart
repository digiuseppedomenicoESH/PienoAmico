import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO Fase 2: implementare dettaglio distributore + navigazione
class DetailScreen extends ConsumerWidget {
  final int distributoreId;
  const DetailScreen({super.key, required this.distributoreId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio')),
      body: Center(child: Text('Distributore #$distributoreId — da implementare')),
    );
  }
}
