import '../../core/imports.dart';
import 'extrusion_card_widget.dart';
import 'extrusion_edit_screen.dart';

class ExtrusionScreen extends StatefulWidget {
  const ExtrusionScreen({super.key});

  @override
  State<ExtrusionScreen> createState() => _ExtrusionScreenState();
}

class _ExtrusionScreenState extends State<ExtrusionScreen> {
  final List<Map<String, dynamic>> _extrusion = [
    {
      'numero': 'EX-25-01-00001',
      'date': '15/03/2023',
      'horaire': '8:00-16:00',
      'equipe': 'A',
      'conducteur': 'Ahmed Benali',
      'dressage': 'Mohammed Alami',
      'presse': '2',
      'production_data': [
        {
          'nbr_eclt': '1',
          'ref': 'AL-6063',
          'ind': 'A',
          'heur_debut': '8:15',
          'heur_fin': '10:45',
          'nbr_blocs': '25',
          'Lg_blocs': '600',
          'prut_kg': '4500',
          'num_lot_billette': 'BL-2023-145',
          'vitesse': '12',
          'pres_extru': '350',
          'nbr_barres': '120',
          'long': '6000',
          'p_barre_reel': '35.5',
          'net_kg': '4260',
          'Long_eclt': '5950',
          'etirage_kg': '4300',
          'taux_de_chutes': '5.33',
          'nbr_barres_chutes': '6',
          'observation': 'Production normale, qualité conforme',
        },
      ],
      'arrets': [
        {
          'debut': '10:45',
          'fin': '11:00',
          'duree': '15 min',
          'cause': 'Changement de billette',
          'action': 'Préparation matière',
        },
        {
          'debut': '12:30',
          'fin': '13:00',
          'duree': '30 min',
          'cause': 'Pause déjeuner',
          'action': 'Pause équipe',
        },
      ],
      'culot': {
        'par_NC': '3',
        'culot': '180',
        'pag': '45',
        'FO': '12',
        'retour_F': '8',
        'total': '248',
      },
      'total_arrets': '45 min',
    },
  ];

  List<Map<String, dynamic>> get _displayedInventory => _extrusion;

  @override
  Widget build(BuildContext context) {
    final displayedInventory = _displayedInventory;

    return Scaffold(
      body: displayedInventory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 66,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune fiche d\'extrusion disponible',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: displayedInventory.length,
              itemBuilder: (context, index) {
                final fiche = displayedInventory[index];
                return ExtrusionCard(
                  fiche: fiche,
                  onEdit: () => _handleEditFiche(context, fiche),
                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmer la suppression'),
                        content: Text(
                          'Supprimer la fiche N° ${fiche['numero']} ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _extrusion.removeWhere(
                                  (e) => e['numero'] == fiche['numero'],
                                );
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fiche supprimée'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nextNumero = _computeNextNumero();
          final result = await Navigator.push<Map<String, dynamic>?>(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ExtrusionEditScreen(fiche: {'numero': nextNumero ?? ''}),
            ),
          );
          if (!mounted) return;
          if (result != null) {
            _upsertFiche(result);
          }
        },
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _handleEditFiche(
    BuildContext context,
    Map<String, dynamic> fiche,
  ) async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (context) => ExtrusionEditScreen(fiche: fiche),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      _upsertFiche(result);
    }
  }

  void _upsertFiche(Map<String, dynamic> updated) {
    setState(() {
      // حساب total_arrets تلقائياً
      final arrets = (updated['arrets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      int totalMinutes = 0;
      for (final arret in arrets) {
        final dureeStr = arret['duree']?.toString() ?? '';
        final match = RegExp(r'(\d+)').firstMatch(dureeStr);
        if (match != null) {
          totalMinutes += int.tryParse(match.group(1) ?? '0') ?? 0;
        }
      }
      updated['total_arrets'] = '$totalMinutes min';

      final numero = updated['numero']?.toString();
      final index = _extrusion.indexWhere(
        (element) => element['numero']?.toString() == numero,
      );
      if (index >= 0) {
        _extrusion[index] = updated;
      } else {
        _extrusion.add(updated);
      }
    });
  }

  String? _computeNextNumero() {
    if (_extrusion.isEmpty) return '2650';
    final numeros = _extrusion
        .map((e) => int.tryParse(e['numero']?.toString() ?? ''))
        .whereType<int>()
        .toList();
    if (numeros.isEmpty) return '2650';
    numeros.sort();
    return (numeros.last + 1).toString();
  }
}
