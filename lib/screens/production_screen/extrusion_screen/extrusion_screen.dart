import '../../../core/imports.dart';
import 'extrusion_card_widget.dart';
import 'extrusion_edit_screen.dart';
import 'api_services.dart';

class ExtrusionScreen extends StatefulWidget {
  const ExtrusionScreen({super.key});

  @override
  State<ExtrusionScreen> createState() => _ExtrusionScreenState();
}

class _ExtrusionScreenState extends State<ExtrusionScreen> {
  List<Map<String, dynamic>> _extrusions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExtrusions();
  }

  Future<void> _loadExtrusions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final extrusions = await ExtrusionApiService().getAllExtrusions();

      if (!mounted) return;

      setState(() {
        _extrusions = extrusions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 66, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadExtrusions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _extrusions.isEmpty
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
          : RefreshIndicator(
              onRefresh: _loadExtrusions,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: _extrusions.length,
                itemBuilder: (context, index) {
                  final fiche = _extrusions[index];
                  return ExtrusionCard(
                    fiche: fiche,
                    onEdit: () => _handleEditFiche(context, fiche),
                    onDelete: () => _handleDeleteFiche(context, fiche),
                    onPrint: () => _handlePrintFiche(context, fiche),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Try to get next numero from API, fallback to local calculation
          String nextNumero;
          try {
            nextNumero = await ExtrusionApiService().getNextNumero();
          } catch (e) {
            // Fallback to local calculation if API fails
            nextNumero = _computeNextNumero();
          }

          if (!context.mounted) return;

          final result = await Navigator.push<Map<String, dynamic>?>(
            context,
            MaterialPageRoute(
              builder: (context) => ExtrusionEditScreen(lastNumero: nextNumero),
            ),
          );
          if (!mounted) return;
          if (result != null && result['success'] == true) {
            _loadExtrusions(); // Reload from API
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
    try {
      // Fetch fresh data from API
      final ficheData = await ExtrusionApiService().getExtrusionByRef(
        fiche['numero'],
      );

      if (!context.mounted) return;

      final result = await Navigator.push<Map<String, dynamic>?>(
        context,
        MaterialPageRoute(
          builder: (context) => ExtrusionEditScreen(fiche: ficheData),
        ),
      );

      if (!context.mounted) return;

      if (result != null && result['success'] == true) {
        _loadExtrusions(); // Reload from API
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fiche mise à jour avec succès'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handlePrintFiche(
    BuildContext context,
    Map<String, dynamic> ficheHeader,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Fetch full extrusion details
      final fullFiche = await ExtrusionApiService().getExtrusionByRef(
        ficheHeader['numero'],
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Imprimer la fiche'),
          content: Text(
            'Voulez-vous imprimer la fiche d\'extrusion N° ${ficheHeader['numero']} ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final pdfData =
                      await PrintExtrusionService.generateExtrusionPdf(
                        fullFiche,
                      );
                  await Printing.layoutPdf(
                    onLayout: (format) async => pdfData,
                    name: 'Extrusion_${ficheHeader['numero']}',
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur d\'impression: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.print, color: Colors.white, size: 18),
              label: const Text(
                'Imprimer',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleDeleteFiche(
    BuildContext context,
    Map<String, dynamic> ficheHeader,
  ) async {
    try {
      // Show loading indicator while checking status
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Fetch full extrusion details to check item statuses
      final fullFiche = await ExtrusionApiService().getExtrusionByRef(
        ficheHeader['numero'],
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      final productionData = fullFiche['production'] as List<dynamic>? ?? [];

      // Check if any item is completed
      final hasCompletedItems = productionData.any((item) {
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
              'La fiche N° ${ficheHeader['numero']} contient des articles marqués comme "Terminé".\n\n'
              'Pour supprimer cette fiche, vous devez d\'abord réinitialiser le statut de tous les articles à "En cours" afin d\'annuler les mouvements de stock.',
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
            'Voulez-vous vraiment supprimer la fiche N° ${ficheHeader['numero']} ?\n\nCette action est irréversible.',
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

                  await ExtrusionApiService().deleteExtrusion(
                    ficheHeader['numero'],
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context); // Close loading dialog

                  _loadExtrusions(); // Reload from API
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fiche supprimée'),
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
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  /// Compute next numero locally (fallback)
  /// Format: EX-YY-MM-NNNNN
  /// - EX: Operation prefix
  /// - YY: Current year (last 2 digits)
  /// - MM: Current month
  /// - NNNNN: Sequential number (5 digits, resets each month)
  String _computeNextNumero() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2); // "25" for 2025
    final month = now.month.toString().padLeft(2, '0'); // "01" for January

    // Build prefix for current year-month: EX-YY-MM-
    final currentPrefix = 'EX-$year-$month-';

    if (_extrusions.isEmpty) {
      return '${currentPrefix}00001';
    }

    final regex = RegExp(r'^EX-\d{2}-\d{2}-(\d{5})$');
    int bestSeq = 0;

    for (final extrusion in _extrusions) {
      final numero = extrusion['numero']?.toString() ?? '';
      // Only count numeros that match the current year-month prefix
      if (numero.startsWith(currentPrefix)) {
        final match = regex.firstMatch(numero);
        if (match != null) {
          final seq = int.tryParse(match.group(1)!) ?? 0;
          if (seq > bestSeq) {
            bestSeq = seq;
          }
        }
      }
    }

    final nextSeq = (bestSeq + 1).toString().padLeft(5, '0');
    return '$currentPrefix$nextSeq';
  }
}
