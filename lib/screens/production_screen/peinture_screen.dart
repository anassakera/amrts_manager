import '../../core/imports.dart';

class PeintureScreen extends StatefulWidget {
  const PeintureScreen({super.key});

  @override
  State<PeintureScreen> createState() => _PeintureScreenState();
}

class _PeintureScreenState extends State<PeintureScreen> {
  final List<Map<String, dynamic>> _peinture = [
    {
      'date': '15/03/2023',
      'ref_doc': 'PE-25-01-00001',
      'ref': 'AL-6063-PEIN',
      'designations': 'Profilé aluminium extrudé - Traitement peinture époxy',
      'qte': 120,
      'poid_barre': 35.5,
      'poid': 4260.0,
      'dichet': 213.0,
      'poid_net': 4047.0,
      'couleur': 'RAL 9016 - Blanc signalisation',
      'cout_production_unitaire': 185.50,
      'prix_vente': 245.00,
      'type': 'Peinture liquide époxy',
      'source': 'Production locale',
      'observations': 'Qualité conforme aux normes ISO 9001',
      'statut': 'Terminé',
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Peinture Screen')));
  }
}
