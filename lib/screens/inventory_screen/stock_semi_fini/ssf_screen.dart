import '../../../core/imports.dart';
import 'ssf_card_widget.dart';
import 'ssf_edit_screen.dart';
import 'api_services.dart';

class SsfScreen extends StatefulWidget {
  final String searchQuery;

  const SsfScreen({super.key, this.searchQuery = ''});

  @override
  State<SsfScreen> createState() => _SsfScreenState();
}

class _SsfScreenState extends State<SsfScreen> {
  List<Map<String, dynamic>> ssfData = [];
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> get filteredSsfData {
    if (widget.searchQuery.isEmpty) {
      return ssfData;
    }

    final query = widget.searchQuery.toLowerCase();
    return ssfData.where((ssf) {
      return (ssf['ref_code']?.toString().toLowerCase().contains(query) ??
              false) ||
          (ssf['status']?.toString().toLowerCase().contains(query) ?? false) ||
          (ssf['total_quantity']?.toString().toLowerCase().contains(query) ??
              false) ||
          (ssf['total_weight']?.toString().toLowerCase().contains(query) ??
              false) ||
          (ssf['total_amount']?.toString().toLowerCase().contains(query) ??
              false) ||
          (ssf['operations_count']?.toString().toLowerCase().contains(query) ??
              false);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadSsfData();
  }

  Future<void> _loadSsfData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await InventorySsfApiService.getAllInventorySsf();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          ssfData = (result['data'] as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load data';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  String? _getLastRefCode() {
    if (ssfData.isEmpty) return null;
    final reg = RegExp(r'^REF(\d{3})$');
    String? bestRef;
    int bestSeq = -1;
    for (final s in ssfData) {
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
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadSsfData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final displayedSsfData = filteredSsfData;

    return Scaffold(
      body: displayedSsfData.isEmpty
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
              itemCount: displayedSsfData.length,
              itemBuilder: (context, index) {
                final ssf = displayedSsfData[index];
                return SsfCard(
                  ssf: ssf,
                  onEdit: () => _handleEditSsf(context, ssf),
                  onDelete: () => _handleDeleteSsf(context, ssf),
                );
              },
            ),
    );
  }

  Future<void> _handleEditSsf(
    BuildContext context,
    Map<String, dynamic> ssf,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SsfEditScreen(lastRefCode: _getLastRefCode(), stock: ssf),
      ),
    );

    if (!mounted) return;
    if (result != null && result is Map<String, dynamic>) {
      await _saveSsf(result, isNew: false);
    }
  }

  Future<void> _handleDeleteSsf(
    BuildContext context,
    Map<String, dynamic> ssf,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${ssf['ref_code']} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final result = await InventorySsfApiService.deleteInventorySsf(
        ssf['ref_code'],
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock supprimé avec succès'),
            duration: Duration(seconds: 2),
          ),
        );
        await _loadSsfData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la suppression'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _saveSsf(
    Map<String, dynamic> result, {
    required bool isNew,
  }) async {
    try {
      final apiResult = isNew
          ? await InventorySsfApiService.createInventorySsf(result)
          : await InventorySsfApiService.updateInventorySsf(result);

      if (!mounted) return;

      if (apiResult['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNew ? 'Stock créé avec succès' : 'Stock mis à jour avec succès',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        await _loadSsfData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              apiResult['message'] ?? 'Erreur lors de la sauvegarde',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
