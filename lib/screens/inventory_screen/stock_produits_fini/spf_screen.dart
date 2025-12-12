import '../../../core/imports.dart';
import 'api_services.dart';
import 'spf_card_widget.dart';
import 'spf_edit_screen.dart';

class SpfScreen extends StatefulWidget {
  final String searchQuery;

  const SpfScreen({super.key, this.searchQuery = ''});

  @override
  State<SpfScreen> createState() => _SpfScreenState();
}

class _SpfScreenState extends State<SpfScreen> {
  List<Map<String, dynamic>> spfData = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSpfData();
  }

  Future<void> _loadSpfData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await InventorySpfApiService.getAllInventorySpf();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          spfData =
              (result['data'] as List?)
                  ?.map((item) => Map<String, dynamic>.from(item))
                  .toList() ??
              [];
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

  List<Map<String, dynamic>> get filteredSpfData {
    if (widget.searchQuery.isEmpty) {
      return spfData;
    }

    final query = widget.searchQuery.toLowerCase();
    return spfData.where((spf) {
      return (spf['ref_code']?.toString().toLowerCase().contains(query) ??
              false) ||
          (spf['product_name']?.toString().toLowerCase().contains(query) ??
              false) ||
          (spf['status']?.toString().toLowerCase().contains(query) ?? false) ||
          (spf['color']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  }

  String? _getLastRefCode() {
    if (spfData.isEmpty) return null;
    final reg = RegExp(r'^SPF([\d]+)$');
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
                style: TextStyle(fontSize: 16, color: Colors.red.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSpfData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final displayedSpfData = filteredSpfData;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadSpfData,
        child: displayedSpfData.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.searchQuery.isEmpty
                                ? 'Aucun produit fini en stock'
                                : 'Aucun résultat trouvé',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 1),
                itemCount: displayedSpfData.length,
                itemBuilder: (context, index) {
                  final spf = displayedSpfData[index];
                  return SpfCard(
                    spf: spf,
                    onEdit: () => _handleEditSpf(context, spf),
                    onDelete: () => _handleDeleteSpf(context, spf),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _handleDeleteSpf(
    BuildContext context,
    Map<String, dynamic> spf,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${spf['ref_code']} ?'),
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

    if (confirmed != true || !mounted) return;

    try {
      final result = await InventorySpfApiService.deleteInventorySpf(
        spf['ref_code'],
      );

      if (!mounted) return;

      if (result['success'] == true) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadSpfData();
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleEditSpf(BuildContext context, Map<String, dynamic> spf) async {
    // Fetch fresh data from API
    try {
      final freshData = await InventorySpfApiService.getInventorySpfByRef(
        spf['ref_code'],
      );

      if (!mounted) return;

      final spfData = freshData['success'] == true ? freshData['data'] : spf;

      if (!context.mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SpfEditScreen(lastRefCode: _getLastRefCode(), stock: spfData),
        ),
      );

      if (!mounted) return;
      if (result != null && result is Map<String, dynamic>) {
        await _loadSpfData(); // Reload from API
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
