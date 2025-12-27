import '../../../core/imports.dart';
import 'api_services.dart';
import 'peinture_card_widget.dart';
import 'peinture_edit_screen.dart';

class PeintureScreen extends StatefulWidget {
  final String searchQuery;

  const PeintureScreen({super.key, this.searchQuery = ''});

  @override
  State<PeintureScreen> createState() => _PeintureScreenState();
}

class _PeintureScreenState extends State<PeintureScreen> {
  final PeintureApiService _apiService = PeintureApiService();
  List<Map<String, dynamic>> peintures = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPeintures();
  }

  Future<void> _loadPeintures() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _apiService.getAllPeintures();

      if (!mounted) return;

      setState(() {
        peintures = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredPeintures {
    if (widget.searchQuery.isEmpty) {
      return peintures;
    }

    final query = widget.searchQuery.toLowerCase();
    return peintures.where((peinture) {
      return (peinture['ref_peinture']?.toString().toLowerCase().contains(
                query,
              ) ??
              false) ||
          (peinture['total_quantity']?.toString().contains(query) ?? false) ||
          (peinture['operator']?.toString().toLowerCase().contains(query) ??
              false);
    }).toList();
  }

  String? _getLastRefPeinture() {
    if (peintures.isEmpty) return null;
    final reg = RegExp(r'^PE-(\d{2})-(\d{2})-(\d{5})$');
    String? bestRef;
    int bestYY = -1, bestMM = -1, bestSeq = -1;
    for (final p in peintures) {
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

  /// Get next ref_peinture locally (fallback)
  /// Format: PE-YY-MM-NNNNN
  /// - PE: Operation prefix
  /// - YY: Current year (2 digits)
  /// - MM: Current month (2 digits)
  /// - NNNNN: Sequential number (5 digits, resets each month)
  String _computeNextRefPeinture() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2); // "25" for 2025
    final month = now.month.toString().padLeft(2, '0'); // "01" for January

    // Build prefix for current year-month: PE-YY-MM-
    final currentPrefix = 'PE-$year-$month-';

    if (peintures.isEmpty) {
      return '${currentPrefix}00001';
    }

    final reg = RegExp(r'^PE-\d{2}-\d{2}-(\d{5})$');
    int bestSeq = 0;

    for (final p in peintures) {
      final ref = p['ref_peinture']?.toString() ?? '';
      // Only count refs that match the current year-month prefix
      if (ref.startsWith(currentPrefix)) {
        final m = reg.firstMatch(ref);
        if (m != null) {
          final seq = int.tryParse(m.group(1)!) ?? 0;
          if (seq > bestSeq) {
            bestSeq = seq;
          }
        }
      }
    }

    final nextSeq = (bestSeq + 1).toString().padLeft(5, '0');
    return '$currentPrefix$nextSeq';
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  errorMessage!,
                  style: TextStyle(fontSize: 16, color: Colors.red.shade600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPeintures,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final displayedPeintures = filteredPeintures;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadPeintures,
        child: displayedPeintures.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.format_paint_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.searchQuery.isEmpty
                                ? 'Aucune fiche de peinture'
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
                itemCount: displayedPeintures.length,
                itemBuilder: (context, index) {
                  final peinture = displayedPeintures[index];
                  return PeintureCard(
                    peinture: peinture,
                    onEdit: () => _handleEditPeinture(context, peinture),
                    onDelete: () => _handleDeletePeinture(context, peinture),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String nextRef;
          try {
            nextRef = await _apiService.getNextNumero();
          } catch (_) {
            nextRef = _computeNextRefPeinture();
          }

          if (!mounted) return;

          if (!context.mounted) return;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PeintureEditScreen(lastRefPeinture: nextRef),
            ),
          );

          if (!mounted) return;

          if (result == true || (result != null && result is Map)) {
            _loadPeintures();
          }
        },
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _handleDeletePeinture(
    BuildContext context,
    Map<String, dynamic> peinture,
  ) async {
    // Check for completed items
    final items = peinture['items'] as List? ?? [];
    final hasCompletedItems = items.any(
      (item) =>
          (item as Map<String, dynamic>)['status']?.toString() == 'completed',
    );

    if (hasCompletedItems) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Suppression impossible'),
          content: Text(
            'La fiche ${peinture['ref_peinture']} contient des articles marqués comme "Terminé".\n\n'
            'Pour supprimer cette fiche, vous devez d\'abord réinitialiser le statut de tous les articles.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer ${peinture['ref_peinture']} ?',
        ),
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
      await _apiService.deletePeinture(peinture['ref_peinture']);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fiche supprimée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      _loadPeintures();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleEditPeinture(
    BuildContext context,
    Map<String, dynamic> peinture,
  ) async {
    try {
      // Fetch fresh data from API
      final freshData = await _apiService.getPeintureByRef(
        peinture['ref_peinture'],
      );

      if (!mounted) return;

      if (!context.mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PeintureEditScreen(
            lastRefPeinture: _getLastRefPeinture(),
            production: freshData,
          ),
        ),
      );

      if (!mounted) return;
      if (result == true || (result != null && result is Map)) {
        _loadPeintures();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
