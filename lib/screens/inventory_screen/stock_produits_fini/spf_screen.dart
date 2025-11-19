import '../../../core/imports.dart';
import 'spf_card_widget.dart';
import 'spf_edit_screen.dart';

class SpfScreen extends StatefulWidget {
  final String searchQuery;

  const SpfScreen({super.key, this.searchQuery = ''});

  @override
  State<SpfScreen> createState() => _SpfScreenState();
}

class _SpfScreenState extends State<SpfScreen> {
  final List<Map<String, dynamic>> spfData = [
    {
      'total_quantity': 50,
      'total_weight': 1250.00,
      'total_value': 10000.00,
      'operations_count': 1,
      'status': 'Disponible',
      'ref_code': 'SPF001',
      'items': [
        {
          'id': 1,
          'date': '2025-11-16',
          'doc_ref': 'DOC003',
          'product_ref': 'PREF003',
          'product_name': 'PEINTURE A',
          'quantity': 50,
          'weight_per_unit': 25.00,
          'total_weight': 1250.00,
          'color': 'Red',
          'unit_cost': 150.75,
          'selling_price': 200.00,
          'product_type': 'PF',
          'source': 'ATELIER PEINTURE',
        },
      ],
    },
    {
      'total_quantity': 70,
      'total_weight': 1575.00,
      'total_value': 13300.00,
      'operations_count': 1,
      'status': 'Disponible',
      'ref_code': 'SPF002',
      'items': [
        {
          'id': 2,
          'date': '2025-11-17',
          'doc_ref': 'DOC004',
          'product_ref': 'PREF004',
          'product_name': 'PEINTURE B',
          'quantity': 70,
          'weight_per_unit': 22.50,
          'total_weight': 1575.00,
          'color': 'Blue',
          'unit_cost': 140.00,
          'selling_price': 190.00,
          'product_type': 'PF',
          'source': 'ATELIER PEINTURE',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get filteredSpfData {
    if (widget.searchQuery.isEmpty) {
      return spfData;
    }

    final query = widget.searchQuery.toLowerCase();
    return spfData.where((spf) {
      return (spf['ref_code']?.toString().toLowerCase().contains(query) ??
              false) ||
          (spf['status']?.toString().toLowerCase().contains(query) ?? false) ||
          (spf['total_quantity']?.toString().toLowerCase().contains(query) ??
              false) ||
          (spf['total_weight']?.toString().toLowerCase().contains(query) ??
              false) ||
          (spf['total_value']?.toString().toLowerCase().contains(query) ??
              false) ||
          (spf['operations_count']?.toString().toLowerCase().contains(query) ??
              false);
    }).toList();
  }

  String? _getLastRefCode() {
    if (spfData.isEmpty) return null;
    final reg = RegExp(r'^SPF(\d{3})$');
    String? bestRef;
    int bestSeq = -1;
    for (final s in spfData) {
      final ref = s['ref_code']?.toString() ?? '';
      final m = reg.firstMatch(ref);
      if (m != null) {
        final seq = int.tryParse(m.group(1)!) ?? 0;
        if (seq > bestSeq) {
          bestSeq = seq;
          bestRef = ref;
        }
      }
    }
    return bestRef;
  }

  @override
  Widget build(BuildContext context) {
    final displayedSpfData = filteredSpfData;

    return Scaffold(
      body: displayedSpfData.isEmpty
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
              itemCount: displayedSpfData.length,
              itemBuilder: (context, index) {
                final spf = displayedSpfData[index];
                return SpfCard(
                  spf: spf,
                  onEdit: () => _handleEditSpf(context, spf),
                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmer la suppression'),
                        content: Text(
                          'Voulez-vous vraiment supprimer ${spf['ref_code']} ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                spfData.removeWhere(
                                  (s) => s['ref_code'] == spf['ref_code'],
                                );
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Stock supprimé avec succès'),
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
    );
  }

  void _handleEditSpf(BuildContext context, Map<String, dynamic> spf) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SpfEditScreen(lastRefCode: _getLastRefCode(), stock: spf),
      ),
    );

    if (!mounted) return;
    if (result != null && result is Map<String, dynamic>) {
      _upsertSpf(result);
    }
  }

  void _upsertSpf(Map<String, dynamic> result) {
    final List<Map<String, dynamic>> items =
        (result['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    int nextItemId = _highestItemId();
    final normalizedItems = items.map((item) {
      final newItem = Map<String, dynamic>.from(item);
      if (newItem['id'] == null) {
        nextItemId += 1;
        newItem['id'] = nextItemId;
      }
      newItem['status'] = newItem['status'] ?? 'Disponible';
      return newItem;
    }).toList();

    final totalQuantity =
        result['total_quantity'] ??
        normalizedItems.fold<int>(
          0,
          (prev, item) => prev + (item['quantity'] as int? ?? 0),
        );

    final totalWeight =
        result['total_weight'] ??
        normalizedItems.fold<double>(
          0,
          (prev, item) => prev + (item['total_weight'] as num? ?? 0).toDouble(),
        );

    final totalValue =
        result['total_value'] ??
        normalizedItems.fold<double>(
          0,
          (prev, item) {
            final qty = item['quantity'] as int? ?? 0;
            final price = (item['selling_price'] as num? ?? 0).toDouble();
            return prev + (qty * price);
          },
        );

    final operationsCount =
        result['operations_count'] ?? normalizedItems.length;

    final updatedSpf = <String, dynamic>{
      'ref_code': result['ref_code'],
      'status': result['status'] ?? 'Disponible',
      'total_quantity': totalQuantity,
      'total_weight': totalWeight,
      'total_value': totalValue,
      'operations_count': operationsCount,
      'items': normalizedItems,
    };

    setState(() {
      final index = spfData.indexWhere(
        (s) => s['ref_code'] == updatedSpf['ref_code'],
      );
      if (index >= 0) {
        spfData[index] = updatedSpf;
      } else {
        spfData.add(updatedSpf);
      }
    });
  }

  int _highestItemId() {
    return spfData
        .expand(
          (spf) => (spf['items'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        )
        .fold<int>(
          0,
          (previousValue, item) => ((item['id'] as int?) ?? 0) > previousValue
              ? (item['id'] as int?) ?? 0
              : previousValue,
        );
  }
}