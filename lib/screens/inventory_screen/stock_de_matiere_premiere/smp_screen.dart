import '../../../core/imports.dart';
import 'smp_card_widget.dart';
import 'smp_edit_screen.dart';
import 'api_services.dart';

class SmpScreen extends StatefulWidget {
  final String searchQuery;

  const SmpScreen({super.key, this.searchQuery = ''});

  @override
  State<SmpScreen> createState() => _SmpScreenState();
}

class _SmpScreenState extends State<SmpScreen> {
  List<Map<String, dynamic>> smpData = [];
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> get filteredSmpData {
    if (widget.searchQuery.isEmpty) {
      return smpData;
    }

    final query = widget.searchQuery.toLowerCase();
    return smpData.where((smp) {
      return (smp['ref_code']?.toString().toLowerCase().contains(query) ??
              false) ||
          (smp['status']?.toString().toLowerCase().contains(query) ?? false) ||
          (smp['total_quantity']?.toString().toLowerCase().contains(query) ??
              false) ||
          (smp['total_amount']?.toString().toLowerCase().contains(query) ??
              false) ||
          (smp['operations_count']?.toString().toLowerCase().contains(query) ??
              false);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadSmpData();
  }

  Future<void> _loadSmpData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    print("object");
    try {
      final result = await InventorySmpApiService.getAllInventorySmp();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          smpData = (result['data'] as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load data';
          isLoading = false;
        });
        print(errorMessage);
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
    if (smpData.isEmpty) return null;
    final reg = RegExp(r'^REF(\d{3})$');
    String? bestRef;
    int bestSeq = -1;
    for (final s in smpData) {
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
                onPressed: _loadSmpData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final displayedSmpData = filteredSmpData;

    return Scaffold(
      body: displayedSmpData.isEmpty
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
              itemCount: displayedSmpData.length,
              itemBuilder: (context, index) {
                final smp = displayedSmpData[index];
                return SmpCard(
                  smp: smp,
                  onEdit: () => _handleEditSmp(context, smp),
                  onDelete: () => _handleDeleteSmp(context, smp),
                );
              },
            ),
    );
  }

  Future<void> _handleEditSmp(
    BuildContext context,
    Map<String, dynamic> smp,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SmpEditScreen(lastRefCode: _getLastRefCode(), stock: smp),
      ),
    );

    if (!mounted) return;
    if (result != null && result is Map<String, dynamic>) {
      await _saveSmp(result, isNew: false);
    }
  }

  Future<void> _handleDeleteSmp(
    BuildContext context,
    Map<String, dynamic> smp,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${smp['ref_code']} ?'),
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
      final result = await InventorySmpApiService.deleteInventorySmp(
        smp['ref_code'],
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock supprimé avec succès'),
            duration: Duration(seconds: 2),
          ),
        );
        await _loadSmpData();
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

  Future<void> _saveSmp(
    Map<String, dynamic> result, {
    required bool isNew,
  }) async {
    try {
      final apiResult = isNew
          ? await InventorySmpApiService.createInventorySmp(result)
          : await InventorySmpApiService.updateInventorySmp(result);

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
        await _loadSmpData();
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
