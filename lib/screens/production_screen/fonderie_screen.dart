import '../../core/imports.dart';
import 'fonderie_card_widget.dart';
import 'fonderie_edit_screen.dart';

class FonderieScreen extends StatefulWidget {
  final String searchQuery;

  const FonderieScreen({super.key, this.searchQuery = ''});

  @override
  State<FonderieScreen> createState() => _FonderieScreenState();
}

class _FonderieScreenState extends State<FonderieScreen> {
  final List<Map<String, dynamic>> fondries = [
    {
      'ref_fondrie': 'FO-25-01-00001',
      'total_quantity': 120,
      'total_cout': 860.0,
      'operations_count': 1,
      'items': [
        {
          'id': 1,
          'ref_article': 'ART-001',
          'articleName': 'Profilé Aluminium A',
          'quantity': 120,
          'dechet_fondrie': 3.5,
          'billete': 45.0,
          'propane': 12.0,
          'cout': 860.0,
          'date': '2025-01-12',
          'time': '08:30',
          'status': 'completed',
        },
      ],
    },
    {
      'ref_fondrie': 'FO-25-01-00002',

      'total_quantity': 95,
      'total_cout': 745.0,
      'operations_count': 1,
      'items': [
        {
          'id': 2,
          'ref_article': 'ART-002',
          'articleName': 'Profilé Aluminium B',
          'quantity': 95,
          'dechet_fondrie': 2.1,
          'billete': 38.0,
          'propane': 10.5,
          'cout': 745.0,
          'date': '2025-01-13',
          'time': '10:15',
          'status': 'completed',
        },
      ],
    },
    {
      'ref_fondrie': 'FO-25-01-00003',

      'total_quantity': 105,
      'total_cout': 910.0,
      'operations_count': 1,
      'items': [
        {
          'id': 3,
          'ref_article': 'ART-003',
          'articleName': 'Profilé Aluminium C',
          'quantity': 105,
          'dechet_fondrie': 4.0,
          'billete': 50.0,
          'propane': 13.2,
          'cout': 910.0,
          'date': '2025-01-14',
          'time': '14:45',
          'status': 'completed',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get filteredFondries {
    if (widget.searchQuery.isEmpty) {
      return fondries;
    }

    final query = widget.searchQuery.toLowerCase();
    return fondries.where((fondry) {
      return (fondry['ref_fondrie']?.toString().toLowerCase().contains(query) ??
              false) ||
          (fondry['ref_article']?.toString().toLowerCase().contains(query) ??
              false) ||
          (fondry['articleName']?.toString().toLowerCase().contains(query) ??
              false) ||
          (fondry['total_quantity']?.toString().toLowerCase().contains(query) ??
              false) ||
          (fondry['total_cout']?.toString().toLowerCase().contains(query) ??
              false) ||
          (fondry['operations_count']?.toString().toLowerCase().contains(
                query,
              ) ??
              false);
    }).toList();
  }

  String? _getLastRefFondrie() {
    if (fondries.isEmpty) return null;
    final reg = RegExp(r'^FO-(\d{2})-(\d{2})-(\d{5})$');
    String? bestRef;
    int bestYY = -1, bestMM = -1, bestSeq = -1;
    for (final f in fondries) {
      final ref = f['ref_fondrie']?.toString() ?? '';
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
    final displayedFondries = filteredFondries;

    return Scaffold(
      body: displayedFondries.isEmpty
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
              itemCount: displayedFondries.length,
              itemBuilder: (context, index) {
                final fondry = displayedFondries[index];
                return FonderieCard(
                  fondry: fondry,

                  onEdit: () => _handleEditFondry(context, fondry),
                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmer la suppression'),
                        content: Text(
                          'Voulez-vous vraiment supprimer ${fondry['ref_article']} ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                fondries.removeWhere(
                                  (f) =>
                                      f['ref_fondrie'] == fondry['ref_fondrie'],
                                );
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Article supprimé avec succès'),
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
          final lastRef = _getLastRefFondrie();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FonderieEditScreen(lastRefFonderie: lastRef),
            ),
          );

          if (!mounted) return;

          if (result != null && result is Map<String, dynamic>) {
            _upsertFondry(result);
          }
        },
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _handleEditFondry(
    BuildContext context,
    Map<String, dynamic> fondry,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FonderieEditScreen(
          lastRefFonderie: _getLastRefFondrie(),
          production: fondry,
        ),
      ),
    );

    if (!mounted) return;
    if (result != null && result is Map<String, dynamic>) {
      _upsertFondry(result);
    }
  }

  void _upsertFondry(Map<String, dynamic> result) {
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
          (prev, item) => prev + (item['quantity'] as int? ?? 0),
        );
    final totalCout =
        result['total_cout'] ??
        normalizedItems.fold<double>(
          0,
          (prev, item) => prev + (item['cout'] as num? ?? 0).toDouble(),
        );
    final operationsCount =
        result['operations_count'] ?? normalizedItems.length;

    final updatedFondry = <String, dynamic>{
      'ref_fondrie': result['ref_fondrie'],
      'ref_article': result['ref_article'],
      'articleName': result['articleName'],
      'total_quantity': totalQuantity,
      'total_cout': totalCout,
      'operations_count': operationsCount,
      'items': normalizedItems,
    };

    setState(() {
      final index = fondries.indexWhere(
        (f) => f['ref_fondrie'] == updatedFondry['ref_fondrie'],
      );
      if (index >= 0) {
        fondries[index] = updatedFondry;
      } else {
        fondries.add(updatedFondry);
      }
    });
  }

  int _highestItemId() {
    return fondries
        .expand(
          (fondry) =>
              (fondry['items'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        )
        .fold<int>(
          0,
          (previousValue, item) => ((item['id'] as int?) ?? 0) > previousValue
              ? (item['id'] as int?) ?? 0
              : previousValue,
        );
  }
}
