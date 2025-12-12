import '../../../core/imports.dart';
import 'fonderie_card_widget.dart';
import 'fonderie_edit_screen.dart';
import 'api_services.dart';

class FonderieScreen extends StatefulWidget {
  final String searchQuery;

  const FonderieScreen({super.key, this.searchQuery = ''});

  @override
  State<FonderieScreen> createState() => _FonderieScreenState();
}

class _FonderieScreenState extends State<FonderieScreen> {
  final Set<String> _deletingItems = {};
  final FonderieApiService _apiService = FonderieApiService();
  List<Map<String, dynamic>> fondries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFondries();
  }

  Future<void> _loadFondries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loadedFondries = await _apiService.getAllFondries();
      if (mounted) {
        setState(() {
          fondries = loadedFondries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ في تحميل البيانات: $e';
          _isLoading = false;
        });
      }
    }
  }

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

  /// Get last ref_fondrie locally (fallback)
  /// Format: FO-YY-MM-NNNNN
  /// - FO: Operation prefix
  /// - YY: Current year (2 digits)
  /// - MM: Current month (2 digits)
  /// - NNNNN: Sequential number (5 digits, resets each month)
  String _computeNextRefFondrie() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2); // "25" for 2025
    final month = now.month.toString().padLeft(2, '0'); // "01" for January

    // Build prefix for current year-month: FO-YY-MM-
    final currentPrefix = 'FO-$year-$month-';

    if (fondries.isEmpty) {
      return '${currentPrefix}00001';
    }

    final reg = RegExp(r'^FO-\d{2}-\d{2}-(\d{5})$');
    int bestSeq = 0;

    for (final f in fondries) {
      final ref = f['ref_fondrie']?.toString() ?? '';
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

  Future<void> _handleDelete(Map<String, dynamic> fondryHeader) async {
    try {
      // Show loading indicator while checking status
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Fetch full fondrie details to check item statuses
      final fullFondrie = await _apiService.getFondrieByRef(
        fondryHeader['ref_fondrie'],
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      final items = (fullFondrie['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      // Check if any item is completed
      final hasCompletedItems = items.any((item) {
        final status = item['status']?.toString() ?? 'in_progress';
        return status == 'completed';
      });

      if (hasCompletedItems) {
        // Show warning dialog preventing deletion
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Suppression impossible'),
            content: Text(
              'La fonderie ${fondryHeader['ref_fondrie']} contient des articles marqués comme "Terminé".\n\n'
              'Pour supprimer cette fonderie, vous devez d\'abord réinitialiser le statut de tous les articles à "En cours" afin d\'annuler les mouvements de stock.',
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

      // Proceed with deletion confirmation if safe
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Voulez-vous vraiment supprimer la fonderie ${fondryHeader['ref_fondrie']} ?\n\nCette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  await _apiService.deleteFondrie(fondryHeader['ref_fondrie']);

                  if (!context.mounted) return;
                  Navigator.pop(context); // Close loading dialog

                  _loadFondries(); // Reload from API
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonderie supprimée'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.pop(context); // Close loading dialog

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedFondries = filteredFondries;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 16, color: Colors.red.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadFondries,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : displayedFondries.isEmpty
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
                final fondryId = fondry['ref_fondrie'];
                final isDeleting = _deletingItems.contains(fondryId);

                return FonderieCard(
                  key: ValueKey(fondryId),
                  fondry: fondry,
                  isDeleting: isDeleting,
                  onEdit: () => _handleEditFondry(context, fondry),
                  onDelete: () => _handleDelete(fondry),
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Try to get next ref from API, fallback to local calculation
          String nextRef;
          try {
            nextRef = await _apiService.getNextRefFondrie();
          } catch (e) {
            // Fallback to local calculation if API fails
            nextRef = _computeNextRefFondrie();
          }

          if (!context.mounted) return;

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FonderieEditScreen(lastRefFonderie: nextRef),
            ),
          );

          if (!mounted) return;

          if (result == true) {
            _loadFondries();
          } else if (result != null && result is Map<String, dynamic>) {
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
    // For edit, we don't need the next ref since we're editing existing
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FonderieEditScreen(
          lastRefFonderie: fondry['ref_fondrie']?.toString(),
          production: fondry,
        ),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      _loadFondries();
    } else if (result != null && result is Map<String, dynamic>) {
      _upsertFondry(result);
    }
  }

  Future<void> _upsertFondry(Map<String, dynamic> result) async {
    final List<Map<String, dynamic>> items =
        (result['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final fondrieData = {'ref_fondrie': result['ref_fondrie'], 'items': items};

    try {
      // Check if fondrie exists
      final index = fondries.indexWhere(
        (f) => f['ref_fondrie'] == result['ref_fondrie'],
      );

      if (index >= 0) {
        // Update existing
        await _apiService.updateFondrie(fondrieData);
      } else {
        // Create new
        await _apiService.createFondrie(fondrieData);
      }

      // Reload all fondries to get updated data
      await _loadFondries();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              index >= 0
                  ? 'Production mise à jour avec succès'
                  : 'Production créée avec succès',
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }
}
