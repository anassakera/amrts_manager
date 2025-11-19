import '../../../core/imports.dart';
import 'peinture_card_widget.dart';
import 'peinture_edit_screen.dart';

class PeintureScreen extends StatefulWidget {
  final String searchQuery;

  const PeintureScreen({super.key, this.searchQuery = ''});

  @override
  State<PeintureScreen> createState() => _PeintureScreenState();
}

class _PeintureScreenState extends State<PeintureScreen> {
  final List<Map<String, dynamic>> _peinture = [
    {
      'ref_peinture': 'PE-25-01-00001',
      'total_quantity': 120,
      'total_cout': 22260.0,
      'operations_count': 1,
      'items': [
        {
          'id': 1,
          'ref': 'AL-6063-PEIN',
          'designations':
              'Profilé aluminium extrudé - Traitement peinture époxy',
          'qte': 120,
          'poid_barre': 35.5,
          'poid': 4260.0,
          'dichet': 213.0,
          'poid_net': 4047.0,
          'couleur': 'RAL 9016 - Blanc signalisation',
          'cout_production_unitaire': 185.50,
          'prix_vente': 245.00,
          'type': 'Peinture liquide époxy',
          'date': '2025-01-15',
          'time': '09:00',
          'status': 'completed',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get filteredPeinture {
    if (widget.searchQuery.isEmpty) {
      return _peinture;
    }

    final query = widget.searchQuery.toLowerCase();
    return _peinture.where((peinture) {
      return (peinture['ref_peinture']?.toString().toLowerCase().contains(
                query,
              ) ??
              false) ||
          (peinture['total_quantity']?.toString().toLowerCase().contains(
                query,
              ) ??
              false) ||
          (peinture['total_cout']?.toString().toLowerCase().contains(query) ??
              false) ||
          (peinture['operations_count']?.toString().toLowerCase().contains(
                query,
              ) ??
              false);
    }).toList();
  }

  String? _getLastRefPeinture() {
    if (_peinture.isEmpty) return null;
    final reg = RegExp(r'^PE-(\d{2})-(\d{2})-(\d{5})$');
    String? bestRef;
    int bestYY = -1, bestMM = -1, bestSeq = -1;
    for (final p in _peinture) {
      final ref = p['ref_peinture']?.toString() ?? '';
      final m = reg.firstMatch(ref);
      if (m != null) {
        final yy = int.tryParse(m.group(1)!) ?? 0;
        final mm = int.tryParse(m.group(2)!) ?? 0;
        final seq = int.tryParse(m.group(3)!) ?? 0;
        if (yy > bestYY ||
            (yy == bestYY &&
                (mm > bestMM || (mm == bestMM && seq > bestSeq)))) {
          bestYY = yy;
          bestMM = mm;
          bestSeq = seq;
          bestRef = ref;
        }
      }
    }
    return bestRef;
  }

  @override
  Widget build(BuildContext context) {
    final displayedPeinture = filteredPeinture;

    return Scaffold(
      body: displayedPeinture.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun résultat trouvé',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 1),
              itemCount: displayedPeinture.length,
              itemBuilder: (context, index) {
                final peinture = displayedPeinture[index];
                return PeintureCard(
                  peinture: peinture,
                  onEdit: () => _handleEditPeinture(context, peinture),
                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmer la suppression'),
                        content: Text(
                          'Voulez-vous vraiment supprimer ${peinture['ref_peinture']} ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _peinture.removeWhere(
                                  (p) =>
                                      p['ref_peinture'] ==
                                      peinture['ref_peinture'],
                                );
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Production supprimée avec succès',
                                  ),
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
          final lastRef = _getLastRefPeinture();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PeintureEditScreen(lastRefPeinture: lastRef),
            ),
          );

          if (!mounted) return;

          if (result != null && result is Map<String, dynamic>) {
            _upsertPeinture(result);
          }
        },
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _handleEditPeinture(
    BuildContext context,
    Map<String, dynamic> peinture,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PeintureEditScreen(
          lastRefPeinture: _getLastRefPeinture(),
          production: peinture,
        ),
      ),
    );

    if (!mounted) return;
    if (result != null && result is Map<String, dynamic>) {
      _upsertPeinture(result);
    }
  }

  void _upsertPeinture(Map<String, dynamic> result) {
    final List<Map<String, dynamic>> items =
        (result['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    int nextItemId = _highestItemId();
    final normalizedItems = items.map((item) {
      final newItem = Map<String, dynamic>.from(item);
      if (newItem['id'] == null) {
        nextItemId += 1;
        newItem['id'] = nextItemId;
      }
      newItem['status'] = newItem['status'] ?? 'completed';
      return newItem;
    }).toList();

    final totalQuantity =
        result['total_quantity'] ??
        normalizedItems.fold<int>(
          0,
          (prev, item) => prev + (item['qte'] as int? ?? 0),
        );
    final totalCout =
        result['total_cout'] ??
        normalizedItems.fold<double>(
          0,
          (prev, item) =>
              prev +
              ((item['cout_production_unitaire'] as num? ?? 0).toDouble() *
                  (item['qte'] as num? ?? 0).toDouble()),
        );
    final operationsCount =
        result['operations_count'] ?? normalizedItems.length;

    final updatedPeinture = <String, dynamic>{
      'ref_peinture': result['ref_peinture'],
      'total_quantity': totalQuantity,
      'total_cout': totalCout,
      'operations_count': operationsCount,
      'items': normalizedItems,
    };

    setState(() {
      final index = _peinture.indexWhere(
        (p) => p['ref_peinture'] == updatedPeinture['ref_peinture'],
      );
      if (index >= 0) {
        _peinture[index] = updatedPeinture;
      } else {
        _peinture.add(updatedPeinture);
      }
    });
  }

  int _highestItemId() {
    return _peinture
        .expand(
          (peinture) =>
              (peinture['items'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        )
        .fold<int>(
          0,
          (previousValue, item) => ((item['id'] as int?) ?? 0) > previousValue
              ? (item['id'] as int?) ?? 0
              : previousValue,
        );
  }
}
