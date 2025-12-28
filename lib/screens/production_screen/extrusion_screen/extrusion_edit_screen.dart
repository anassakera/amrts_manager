import '../../../core/imports.dart';
import 'api_services.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

class _ExtrusionConstants {
  static const headerFields = [
    'numero',
    'date',
    'horaire',
    'equipe',
    'conducteur',
    'dressage',
    'presse',
    'total_arrets',
  ];

  static const productionFields = [
    'id',
    'nbr_eclt',
    'ref',
    'ind',
    'heur_debut',
    'heur_fin',
    'nbr_blocs',
    'Lg_blocs',
    'prut_kg',
    'num_lot_billette',
    'vitesse',
    'pres_extru',
    'nbr_barres',
    'long',
    'p_barre_reel',
    'net_kg',
    'Long_eclt',
    'etirage_kg',
    'CU_EXTRUSION',
    'taux_de_chutes',
    'nbr_barres_chutes',
    'product_name',
    'observation',
    'status',
  ];

  static const arretFields = ['debut', 'fin', 'duree', 'cause', 'action'];

  static const culotFields = [
    'par_NC',
    'culot',
    'Bag',
    'FO',
    'retour_F',
    'POID_DECHET',
    'total',
  ];

  static const intFields = {'nbr_blocs', 'nbr_barres', 'nbr_barres_chutes'};

  static const doubleFields = {
    'Lg_blocs',
    'prut_kg',
    'vitesse',
    'pres_extru',
    'long',
    'p_barre_reel',
    'net_kg',
    'Long_eclt',
    'etirage_kg',
    'CU_EXTRUSION',
    'taux_de_chutes',
  };
}

class _ActionColors {
  static const save = Color(0xFF2196F3);
  static const delete = Color(0xFFF44336);
  static const completed = Color(0xFF4CAF50);
  static const pending = Color(0xFFF59E0B);
}

// ============================================================================
// CALCULATION LOGIC CLASS
// ============================================================================

class ExtrusionCalculationLogic {
  static double calculateBrutKg(double nbrBlocs, double lgBlocs) {
    return nbrBlocs * lgBlocs * 0.033;
  }

  static double calculateNetKg(double nbrBarres, double pBarreReel) {
    return nbrBarres * pBarreReel;
  }

  static double calculateTauxDeChutes(double brutKg, double netKg) {
    return brutKg > 0 ? ((brutKg - netKg) / brutKg) * 100 : 0.0;
  }

  static Map<String, String> calculateProductionValues({
    required double nbrBlocs,
    required double lgBlocs,
    required double nbrBarres,
    required double pBarreReel,
    required double cuExtrusion,
  }) {
    final brutKg = calculateBrutKg(nbrBlocs, lgBlocs);
    final netKg = calculateNetKg(nbrBarres, pBarreReel);
    final tauxDeChutes = calculateTauxDeChutes(brutKg, netKg);

    return {
      'prut_kg': brutKg.toStringAsFixed(2),
      'net_kg': netKg.toStringAsFixed(2),
      'taux_de_chutes': tauxDeChutes.toStringAsFixed(2),
      'CU_EXTRUSION': cuExtrusion.toStringAsFixed(2),
    };
  }

  static double calculateTotalWeight(
    List<Map<String, TextEditingController>> controllers,
  ) {
    return controllers.fold<double>(0, (total, map) {
      final netKg = double.tryParse(map['net_kg']?.text ?? '0') ?? 0;
      return total + netKg;
    });
  }

  static int? parseDureeMinutes(String? duree) {
    if (duree == null || duree.isEmpty) return null;
    return int.tryParse(duree.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  static Map<String, dynamic> buildProductionItem(
    Map<String, TextEditingController> controllers,
  ) {
    final itemData = <String, dynamic>{};
    for (final entry in controllers.entries) {
      final key = entry.key;
      final value = entry.value.text.trim();

      if (key == 'id') {
        if (value.isNotEmpty) {
          final idInt = int.tryParse(value);
          if (idInt != null && idInt > 0) {
            itemData[key] = idInt;
          }
        }
      } else if (_ExtrusionConstants.intFields.contains(key)) {
        if (value.isNotEmpty) {
          final intValue = int.tryParse(value);
          if (intValue != null) itemData[key] = intValue;
        }
      } else if (_ExtrusionConstants.doubleFields.contains(key)) {
        if (value.isNotEmpty) {
          final doubleValue = double.tryParse(value.replaceAll(',', '.'));
          if (doubleValue != null) itemData[key] = doubleValue;
        }
      } else {
        itemData[key] = value.isEmpty ? null : value;
      }
    }
    return itemData;
  }
}

// ============================================================================
// WIDGETS CLASS
// ============================================================================

class ExtrusionEditWidgets {
  static Widget buildActionButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.073,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
    bool isDisabled = false,
  }) {
    final effectiveColor = isDisabled ? Colors.grey : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: isDisabled ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: effectiveColor, width: isDisabled ? 1 : 1.5),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        color: effectiveColor,
        onPressed: isDisabled ? null : onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: tooltip,
      ),
    );
  }

  static Widget buildStatusChip({
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    final color = isCompleted ? _ActionColors.completed : _ActionColors.pending;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.hourglass_empty,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isCompleted ? 'Terminé' : 'En cours',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildTableHeaderFixed(String title, {required double width}) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static Widget buildHeaderCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static Widget buildVerticalDivider({double? height}) {
    return Container(
      width: 1,
      height: height ?? double.infinity,
      color: const Color(0xFFE5E7EB),
    );
  }
}

// ============================================================================
// MAIN SCREEN CLASS
// ============================================================================

class ExtrusionEditScreen extends StatefulWidget {
  final Map<String, dynamic>? fiche;
  final String? lastNumero;

  const ExtrusionEditScreen({super.key, this.fiche, this.lastNumero});

  @override
  State<ExtrusionEditScreen> createState() => _ExtrusionEditScreenState();
}

class _ExtrusionEditScreenState extends State<ExtrusionEditScreen> {
  // ========================================================================
  // STATE VARIABLES
  // ========================================================================
  final Map<String, TextEditingController> _headerControllers = {};
  final List<Map<String, TextEditingController>> _productionControllers = [];
  final List<Map<String, TextEditingController>> _arretControllers = [];
  Map<String, TextEditingController> _culotControllers = {};

  bool _isSaving = false;
  bool _isArretsExpanded = false;
  bool _isCulotExpanded = false;

  List<Map<String, dynamic>> _articles = [];
  bool _isLoadingArticles = false;
  double _cuExtrusion = 0.0;

  final ScrollController _productionHeaderScrollController = ScrollController();
  final ScrollController _productionRowsScrollController = ScrollController();

  // Track editing and saving states
  final Set<int> _editingIndices = {};
  final Set<int> _savingIndices = {};

  // Store extrusion ID after first save
  int? _extrusionId;

  // Track unsaved changes
  bool _hasUnsavedChanges = false;

  // ========================================================================
  // LIFECYCLE METHODS
  // ========================================================================

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupScrollSync();
    _loadArticles();
    _loadCosts();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoadingArticles = true);
    try {
      final results = await ExtrusionApiService.fetchArticles();
      if (!mounted) return;
      setState(() {
        _articles = results;
        _isLoadingArticles = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _isLoadingArticles = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des articles: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _productionHeaderScrollController.dispose();
    _productionRowsScrollController.dispose();
    for (var c in _headerControllers.values) {
      c.dispose();
    }
    for (var map in _productionControllers) {
      for (var c in map.values) {
        c.dispose();
      }
    }
    for (var map in _arretControllers) {
      for (var c in map.values) {
        c.dispose();
      }
    }
    for (var c in _culotControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ========================================================================
  // INITIALIZATION METHODS
  // ========================================================================

  void _setupScrollSync() {
    _productionHeaderScrollController.addListener(() {
      if (_productionRowsScrollController.hasClients &&
          _productionRowsScrollController.offset !=
              _productionHeaderScrollController.offset) {
        _productionRowsScrollController.jumpTo(
          _productionHeaderScrollController.offset,
        );
      }
    });

    _productionRowsScrollController.addListener(() {
      if (_productionHeaderScrollController.hasClients &&
          _productionHeaderScrollController.offset !=
              _productionRowsScrollController.offset) {
        _productionHeaderScrollController.jumpTo(
          _productionRowsScrollController.offset,
        );
      }
    });
  }

  void _initializeData() {
    final now = DateTime.now();
    final defaultDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final source = <String, dynamic>{};
    if (widget.fiche != null) source.addAll(widget.fiche!);

    // Initialize extrusion ID from fiche if available
    if (widget.fiche != null && widget.fiche!['id'] != null) {
      _extrusionId = widget.fiche!['id'] is int
          ? widget.fiche!['id'] as int
          : int.tryParse(widget.fiche!['id'].toString());
    }

    source['numero'] =
        source['numero'] ??
        widget.lastNumero ??
        (widget.fiche == null ? 'EX-25-11-00001' : '');
    source['date'] = source['date'] ?? defaultDate;

    // For new fiche, set horaire with only start time (will be completed on save)
    final startTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (widget.fiche == null) {
      source['horaire'] = startTime;
    } else {
      source['horaire'] = source['horaire'] ?? startTime;
    }

    for (final field in _ExtrusionConstants.headerFields) {
      _headerControllers[field] = TextEditingController(
        text: source[field]?.toString() ?? '',
      );
    }

    final productionList =
        (source['production'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    if (productionList.isEmpty) {
      final formattedTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final controllers = _createProductionControllers({});
      controllers['heur_debut']!.text = formattedTime;
      _productionControllers.add(controllers);
    } else {
      for (var item in productionList) {
        _productionControllers.add(_createProductionControllers(item));
      }
    }

    final arretsList =
        (source['arrets'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    if (arretsList.isEmpty) {
      _arretControllers.add(_createArretControllers({}));
    } else {
      for (var item in arretsList) {
        _arretControllers.add(_createArretControllers(item));
      }
    }

    final culotMap =
        (source['culot'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    if (culotMap.isEmpty) {
      culotMap.addAll({
        for (final key in _ExtrusionConstants.culotFields) key: '',
      });
    }
    _culotControllers = {
      for (final entry in culotMap.entries)
        entry.key: TextEditingController(text: entry.value?.toString() ?? ''),
    };
    for (final key in _ExtrusionConstants.culotFields) {
      _culotControllers.putIfAbsent(key, () => TextEditingController());
    }
  }

  Map<String, TextEditingController> _createProductionControllers(
    Map<String, dynamic> item,
  ) {
    final controllers = <String, TextEditingController>{};
    for (final field in _ExtrusionConstants.productionFields) {
      String value = item[field]?.toString() ?? '';
      if (field == 'status' && value.isEmpty) {
        value = 'in_progress';
      } else if (field == 'CU_EXTRUSION' && value.isEmpty) {
        value = _cuExtrusion.toStringAsFixed(2);
      }
      controllers[field] = TextEditingController(text: value);
    }
    return controllers;
  }

  Map<String, TextEditingController> _createArretControllers(
    Map<String, dynamic> item,
  ) {
    return {
      for (final field in _ExtrusionConstants.arretFields)
        field: TextEditingController(text: item[field]?.toString() ?? ''),
    };
  }

  // ========================================================================
  // DATA LOADING METHODS
  // ========================================================================

  Future<void> _loadCosts() async {
    if (!mounted) return;
    try {
      final response = await ExtrusionApiService().getCosts();
      if (!mounted) return;
      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'];
        if (mounted) {
          setState(() {
            final extrusion = data['CU_EXTRUSION']?.toString() ?? '0';
            _cuExtrusion = double.tryParse(extrusion) ?? 0.0;
            for (var controllers in _productionControllers) {
              controllers['CU_EXTRUSION']?.text = _cuExtrusion.toStringAsFixed(
                2,
              );
            }
          });
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  // ========================================================================
  // CALCULATION METHODS
  // ========================================================================

  void _calculateProduction(int index) {
    final controllers = _productionControllers[index];
    final nbrBlocs = double.tryParse(controllers['nbr_blocs']!.text) ?? 0;
    final lgBlocs = double.tryParse(controllers['Lg_blocs']!.text) ?? 0;
    final nbrBarres = double.tryParse(controllers['nbr_barres']!.text) ?? 0;
    final pBarreReel = double.tryParse(controllers['p_barre_reel']!.text) ?? 0;

    final calculated = ExtrusionCalculationLogic.calculateProductionValues(
      nbrBlocs: nbrBlocs,
      lgBlocs: lgBlocs,
      nbrBarres: nbrBarres,
      pBarreReel: pBarreReel,
      cuExtrusion: _cuExtrusion,
    );

    setState(() {
      calculated.forEach((key, value) {
        controllers[key]?.text = value;
      });
    });
  }

  // ========================================================================
  // VALIDATION METHODS
  // ========================================================================

  bool _isProductionEntryValid(int index) {
    final controllers = _productionControllers[index];
    final requiredFields = [
      'nbr_eclt',
      'ref',
      'ind',
      'nbr_blocs',
      'Lg_blocs',
      'num_lot_billette',
      'vitesse',
      'pres_extru',
      'nbr_barres',
      'long',
      'p_barre_reel',
      'Long_eclt',
      'etirage_kg',
      'heur_debut',
    ];

    for (final field in requiredFields) {
      final controller = controllers[field];
      if (controller == null || controller.text.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  bool _isProductionEntrySaved(int index) {
    final controllers = _productionControllers[index];
    final idStr = controllers['id']?.text;
    return idStr != null && idStr.isNotEmpty && int.tryParse(idStr) != null;
  }

  // ========================================================================
  // CRUD METHODS
  // ========================================================================

  Future<void> _addProductionEntry() async {
    // Prevent adding if any row is in edit mode
    if (_editingIndices.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez terminer la modification de la ligne en cours avant d\'ajouter une nouvelle ligne',
          ),
          backgroundColor: Color(0xFFF59E0B),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Check if last entry is valid and saved (only for new entries without ID)
    if (_productionControllers.isNotEmpty) {
      final lastIndex = _productionControllers.length - 1;
      final lastEntryHasId = _isProductionEntrySaved(lastIndex);

      // Only validate if the last entry is a NEW entry (no ID yet)
      // Existing entries with IDs don't block adding new rows
      if (!lastEntryHasId) {
        // Check if all required fields are filled
        if (!_isProductionEntryValid(lastIndex)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Veuillez remplir tous les champs requis de la ligne actuelle avant d\'ajouter une nouvelle ligne',
              ),
              backgroundColor: Color(0xFFF44336),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // New entry must be saved before adding another
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez enregistrer la ligne actuelle avant d\'ajouter une nouvelle ligne',
            ),
            backgroundColor: Color(0xFFF59E0B),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    setState(() {
      final now = DateTime.now();
      final formattedTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final newControllers = _createProductionControllers({});
      newControllers['heur_debut']!.text = formattedTime;
      _productionControllers.add(newControllers);
    });
  }

  Future<void> _removeProductionEntry(int index) async {
    if (_productionControllers.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez garder au moins une ligne de production'),
          backgroundColor: Color(0xFFF44336),
        ),
      );
      return;
    }

    final controllers = _productionControllers[index];
    final productionIdStr = controllers['id']?.text;
    final productionId = productionIdStr != null && productionIdStr.isNotEmpty
        ? int.tryParse(productionIdStr)
        : null;

    // If item is saved in database, delete it
    if (productionId != null && widget.fiche != null) {
      final extrusionId = widget.fiche!['id'];
      if (extrusionId != null) {
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          await ExtrusionApiService().deleteProductionItem(
            productionId: productionId,
            extrusionId: extrusionId is int
                ? extrusionId
                : int.parse(extrusionId.toString()),
          );

          if (!mounted) return;
          Navigator.pop(context);
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() {
      _productionControllers.removeAt(index).values.forEach((c) => c.dispose());
    });
  }

  Future<void> _addArretEntry() async {
    // Validate last arret entry if exists
    if (_arretControllers.isNotEmpty) {
      final lastIndex = _arretControllers.length - 1;
      final lastControllers = _arretControllers[lastIndex];
      final debut = lastControllers['debut']?.text.trim() ?? '';
      final fin = lastControllers['fin']?.text.trim() ?? '';
      final cause = lastControllers['cause']?.text.trim() ?? '';

      if (debut.isEmpty || fin.isEmpty || cause.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez remplir les champs requis (Début, Fin, Cause) avant d\'ajouter une nouvelle ligne',
            ),
            backgroundColor: Color(0xFFF44336),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }
    setState(() => _arretControllers.add(_createArretControllers({})));
  }

  // Calculate duration between two times in minutes
  int? _calculateDureeMinutes(String debut, String fin) {
    if (debut.isEmpty || fin.isEmpty) return null;
    try {
      final debutParts = debut.split(':');
      final finParts = fin.split(':');
      if (debutParts.length != 2 || finParts.length != 2) return null;

      final debutMinutes =
          int.parse(debutParts[0]) * 60 + int.parse(debutParts[1]);
      final finMinutes = int.parse(finParts[0]) * 60 + int.parse(finParts[1]);

      return finMinutes - debutMinutes;
    } catch (e) {
      return null;
    }
  }

  // Update duree field when debut or fin changes
  void _updateArretDuree(int index) {
    final controllers = _arretControllers[index];
    final debut = controllers['debut']?.text ?? '';
    final fin = controllers['fin']?.text ?? '';
    final dureeMinutes = _calculateDureeMinutes(debut, fin);

    if (dureeMinutes != null && dureeMinutes >= 0) {
      controllers['duree']?.text = '$dureeMinutes min';
    } else {
      controllers['duree']?.text = '';
    }
  }

  // Show time picker for arret fields
  Future<void> _showTimePicker(
    TextEditingController controller,
    int arretIndex,
  ) async {
    final now = TimeOfDay.now();
    TimeOfDay initialTime = now;

    // Parse existing value if any
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        if (parts.length == 2) {
          initialTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (_) {}
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _hasUnsavedChanges = true;
        controller.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _updateArretDuree(arretIndex);
      });
    }
  }

  // Calculate culot total
  void _calculateCulotTotal() {
    final fields = ['par_NC', 'culot', 'Bag', 'FO', 'retour_F', 'POID_DECHET'];
    double total = 0;
    for (final field in fields) {
      final value = double.tryParse(_culotControllers[field]?.text ?? '') ?? 0;
      total += value;
    }
    _culotControllers['total']?.text = total.toStringAsFixed(2);
  }

  // Calculate Total brut (Kg) - sum of prut_kg from all production items
  double _calculateTotalBrut() {
    double total = 0;
    for (final controllers in _productionControllers) {
      final value = double.tryParse(controllers['prut_kg']?.text ?? '') ?? 0;
      total += value;
    }
    return total;
  }

  // Calculate Total net (Kg) - sum of net_kg from all production items
  double _calculateTotalNet() {
    double total = 0;
    for (final controllers in _productionControllers) {
      final value = double.tryParse(controllers['net_kg']?.text ?? '') ?? 0;
      total += value;
    }
    return total;
  }

  // Calculate average Chutes (%) - average of taux_de_chutes from all production items
  double _calculateAverageChutes() {
    if (_productionControllers.isEmpty) return 0;
    double total = 0;
    int count = 0;
    for (final controllers in _productionControllers) {
      final value =
          double.tryParse(controllers['taux_de_chutes']?.text ?? '') ?? 0;
      if (value > 0) {
        total += value;
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }

  // Calculate total arret duration in minutes
  int _calculateTotalArretMinutes() {
    int total = 0;
    for (final controllers in _arretControllers) {
      final dureeText = controllers['duree']?.text ?? '';
      // Parse "120 min" format
      final minutes =
          int.tryParse(dureeText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      total += minutes;
    }
    return total;
  }

  void _removeArretEntry(int index) {
    if (_arretControllers.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez garder au moins une ligne d\'arrêt'),
          backgroundColor: Color(0xFFF44336),
        ),
      );
      return;
    }
    setState(() {
      _arretControllers.removeAt(index).values.forEach((c) => c.dispose());
    });
  }

  void _toggleEditMode(int index) {
    setState(() {
      if (_editingIndices.contains(index)) {
        _editingIndices.remove(index);
      } else {
        _editingIndices.add(index);
      }
    });
  }

  /// Handle back button - return without saving (for viewing only)
  void _handleBack() {
    Navigator.pop(context);
  }

  /// Handle cancel button - show confirmation if there are unsaved changes
  Future<void> _handleCancel() async {
    if (_hasUnsavedChanges) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Modifications non enregistrées',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: const Text(
            'Vous avez des modifications non enregistrées. Voulez-vous vraiment quitter sans enregistrer?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Non, continuer',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Oui, quitter',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        if (!mounted) return;
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _saveProductionRow(int index) async {
    final controllers = _productionControllers[index];

    // Validate required fields
    if (!_isProductionEntryValid(index)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez remplir tous les champs requis avant d\'enregistrer',
          ),
          backgroundColor: Color(0xFFF44336),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // ✅ Check billette (BI002) stock availability in SMP BEFORE saving
    final prutKgText = controllers['prut_kg']?.text.trim() ?? '0';
    final prutKg = double.tryParse(prutKgText) ?? 0.0;

    if (prutKg > 0) {
      // Show loading indicator
      setState(() {
        _savingIndices.add(index);
      });

      try {
        final stockCheck = await ExtrusionApiService().checkStockSMP(
          requiredQty: prutKg,
        );

        if (!mounted) return;

        final isAvailable = stockCheck['available'] == true;
        final currentStock = stockCheck['current_stock'] ?? 0.0;

        if (!isAvailable) {
          setState(() {
            _savingIndices.remove(index);
          });

          // Show error dialog with stock info
          final foundInSMP = stockCheck['found_in_smp'] ?? false;
          final foundName = stockCheck['found_name']?.toString() ?? 'Billette';

          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 16,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.warning_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stock insuffisant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Quantité demandée non disponible',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Material Info Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_rounded,
                                    color: Color(0xFF3B82F6),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Matière première',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        foundName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: foundInSMP
                                        ? const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.1)
                                        : const Color(
                                            0xFFEF4444,
                                          ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    foundInSMP ? 'Trouvé' : 'Non trouvé',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: foundInSMP
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Stock Info Row
                          Row(
                            children: [
                              // Available Stock
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.inventory_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Disponible',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF991B1B),
                                        ),
                                      ),
                                      Text(
                                        '${currentStock.toStringAsFixed(2)} Kg',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Required Quantity
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFCD34D),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart_rounded,
                                        color: Color(0xFFD97706),
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Requis',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                      Text(
                                        '${prutKg.toStringAsFixed(2)} Kg',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Info message
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFF6B7280),
                                  size: 18,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Veuillez vérifier le stock de matières premières (SMP).',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Compris',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          return;
        }
      } catch (e) {
        // If stock check fails, allow save but warn user
        debugPrint('Stock check failed: $e');
      }

      if (mounted) {
        setState(() {
          _savingIndices.remove(index);
        });
      }
    }

    // تعيين heur_fin تلقائيًا إذا كان فارغًا
    if (controllers['heur_fin']!.text.trim().isEmpty) {
      final now = DateTime.now();
      final formattedTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      controllers['heur_fin']!.text = formattedTime;
    }

    // Mark as saving
    setState(() {
      _savingIndices.add(index);
    });

    // If fiche doesn't exist, save it first, then save the production item
    if (widget.fiche == null) {
      await _saveFiche(shouldPop: false);

      // After saving fiche, get the extrusion ID and save the production item
      final extrusionId = _extrusionId;
      if (extrusionId == null) {
        setState(() {
          _savingIndices.remove(index);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Impossible de récupérer l\'ID de la fiche'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Now save the production item
      try {
        final itemData = <String, dynamic>{};
        controllers.forEach((key, controller) {
          if (key != 'id') itemData[key] = controller.text.trim();
        });

        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        final result = await ExtrusionApiService().createProductionItem(
          extrusionId: extrusionId,
          itemData: itemData,
        );

        if (!mounted) return;
        Navigator.pop(context);

        if (result['data']?['id'] != null) {
          setState(() {
            controllers['id']?.text = result['data']['id'].toString();
            _savingIndices.remove(index);
            _editingIndices.remove(index);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    result['message'] ?? 'Production enregistrée avec succès',
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            _savingIndices.remove(index);
          });
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        setState(() {
          _savingIndices.remove(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // For existing fiche, save individual item
    final extrusionId = _extrusionId ?? widget.fiche?['id'];
    if (extrusionId == null) {
      setState(() {
        _savingIndices.remove(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de sauvegarder: ID de fiche introuvable'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final itemData = <String, dynamic>{};
      controllers.forEach((key, controller) {
        if (key != 'id') itemData[key] = controller.text.trim();
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final productionIdStr = controllers['id']?.text;
      final productionId = productionIdStr != null && productionIdStr.isNotEmpty
          ? int.tryParse(productionIdStr)
          : null;

      final result = productionId != null
          ? await ExtrusionApiService().updateProductionItem(
              productionId: productionId,
              extrusionId: extrusionId is int
                  ? extrusionId
                  : int.parse(extrusionId.toString()),
              itemData: itemData,
            )
          : await ExtrusionApiService().createProductionItem(
              extrusionId: extrusionId is int
                  ? extrusionId
                  : int.parse(extrusionId.toString()),
              itemData: itemData,
            );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['data']?['id'] != null) {
        setState(() {
          controllers['id']?.text = result['data']['id'].toString();
          _savingIndices.remove(index);
          _editingIndices.remove(index);
        });
      } else {
        setState(() {
          _savingIndices.remove(index);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(result['message'] ?? 'Production enregistrée avec succès'),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      setState(() {
        _savingIndices.remove(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _toggleItemStatus(int index) async {
    final controllers = _productionControllers[index];
    final currentStatus = controllers['status']!.text;
    final newStatus = currentStatus == 'in_progress'
        ? 'completed'
        : 'in_progress';
    final productionIdStr = controllers['id']?.text;

    if (productionIdStr == null || productionIdStr.isEmpty) {
      final now = DateTime.now();
      final formattedTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      setState(() {
        controllers['status']!.text = newStatus;
        controllers['heur_fin']!.text = newStatus == 'completed'
            ? formattedTime
            : '';
      });
      return;
    }

    final productionId = int.tryParse(productionIdStr);
    if (productionId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le changement de statut'),
        content: Text(
          newStatus == 'completed'
              ? 'Voulez-vous marquer cet article comme terminé?\n\nCela va:\n• Déduire les billettes du stock (basé sur le poids brut)\n• Ajouter les déchets au stock\n• Ajouter les produits finis au stock'
              : 'Voulez-vous réinitialiser cet article?\n\nCela va annuler les mouvements de stock pour cet article.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'completed'
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final itemData = {
      'ref': controllers['ref']!.text,
      'prut_kg': double.tryParse(controllers['prut_kg']!.text) ?? 0.0,
      'nbr_barres': int.tryParse(controllers['nbr_barres']!.text) ?? 0,
      'p_barre_reel': double.tryParse(controllers['p_barre_reel']!.text) ?? 0.0,
      'net_kg': double.tryParse(controllers['net_kg']!.text) ?? 0.0,
      'etirage_kg': double.tryParse(controllers['etirage_kg']!.text) ?? 0.0,
      'culot_kg':
          double.tryParse(_culotControllers['culot']?.text ?? '0') ?? 0.0,
      'CU_EXTRUSION': double.tryParse(controllers['CU_EXTRUSION']!.text) ?? 0.0,
      'product_name': controllers['product_name']!.text,
    };

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ExtrusionApiService().updateProductionItemStatus(
        productionId: productionId,
        oldStatus: currentStatus,
        newStatus: newStatus,
        itemData: itemData,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success']) {
        final now = DateTime.now();
        final formattedTime =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        setState(() {
          controllers['status']!.text = newStatus;
          controllers['heur_fin']!.text = newStatus == 'completed'
              ? formattedTime
              : '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Statut mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showValidationErrorDialog(List<String> missingFields) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Champs requis manquants',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Veuillez remplir les champs suivants',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content - List of missing fields
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...missingFields.map(
                      (field) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFCA5A5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                field,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Compris',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveFiche({bool shouldPop = true}) async {
    // Collect all missing required fields
    final List<String> missingFields = [];

    // Check numero
    final numero = _headerControllers['numero']!.text.trim();
    if (numero.isEmpty) {
      missingFields.add('Numéro');
    }

    // Validate required header fields
    final requiredHeaderFields = {
      'date': 'Date',
      'horaire': 'Horaire',
      'equipe': 'Équipe',
      'conducteur': 'Conducteur',
      'dressage': 'Dressage',
      'presse': 'Presse',
    };

    for (final entry in requiredHeaderFields.entries) {
      final value = _headerControllers[entry.key]?.text.trim() ?? '';
      if (value.isEmpty) {
        missingFields.add(entry.value);
      }
    }

    // POID_DECHET is optional - removed from required validation

    // If there are missing fields, show beautiful dialog
    if (missingFields.isNotEmpty) {
      _showValidationErrorDialog(missingFields);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Update horaire with end time (format: "HH:mm - HH:mm")
      final now = DateTime.now();
      final endTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final currentHoraire = _headerControllers['horaire']?.text ?? '';

      // If horaire doesn't contain " - ", append end time
      if (!currentHoraire.contains(' - ')) {
        _headerControllers['horaire']?.text = '$currentHoraire - $endTime';
      }

      final header = <String, dynamic>{};
      _headerControllers.forEach((key, controller) {
        header[key] = controller.text.trim();
      });
      // Override total_arrets with calculated value as int (not string with 'min')
      header['total_arrets'] = _calculateTotalArretMinutes();

      final arrets = _arretControllers.map((map) {
        final arretData = <String, dynamic>{};
        map.forEach((key, controller) {
          arretData[key] = controller.text.trim();
        });
        // Parse duree_minutes from duree field (e.g., "120 min" -> 120)
        final dureeText = arretData['duree']?.toString() ?? '';
        final dureeMinutes = int.tryParse(
          dureeText.replaceAll(RegExp(r'[^0-9]'), ''),
        );
        if (dureeMinutes != null) arretData['duree_minutes'] = dureeMinutes;
        return arretData;
      }).toList();

      final culot = <String, dynamic>{
        for (final entry in _culotControllers.entries)
          entry.key: entry.value.text.trim(),
      };

      final fiche = {'header': header, 'arrets': arrets, 'culot': culot};

      final result = widget.fiche == null
          ? await ExtrusionApiService().createExtrusion(fiche)
          : await ExtrusionApiService().updateExtrusion(fiche);

      if (!mounted) return;

      if (result['success']) {
        // Reset unsaved changes flag
        _hasUnsavedChanges = false;

        // Update extrusion ID from API response
        if (result['data'] != null) {
          final updatedData = result['data'];

          // Update extrusion ID if available
          if (updatedData['id'] != null) {
            _extrusionId = updatedData['id'] is int
                ? updatedData['id'] as int
                : int.tryParse(updatedData['id'].toString());
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  result['message'] ??
                      (widget.fiche == null
                          ? 'Fiche créée avec succès'
                          : 'Fiche mise à jour avec succès'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (shouldPop) {
          Navigator.pop(context, {'success': true, 'data': result['data']});
        }
      } else {
        throw Exception(result['message'] ?? 'Échec de l\'enregistrement');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erreur: $error')),
            ],
          ),
          backgroundColor: const Color(0xFFF44336),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ========================================================================
  // BUILD METHODS
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
        child: Column(
          children: [
            _buildSmartHeader(),
            Expanded(child: _buildProductionTable()),
            const SizedBox(height: 10),
            _buildArretsTable(),
            const SizedBox(height: 10),
            _buildCulotSection(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartHeader() {
    // Auto-update total_arrets
    final totalMinutes = _calculateTotalArretMinutes();
    _headerControllers['total_arrets']?.text = '$totalMinutes min';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFBFC)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Title, Read-only info chips, and Action Buttons
            Row(
              children: [
                // Title Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.fiche == null
                            ? 'Nouvelle Fiche'
                            : 'Modifier Fiche',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Read-only Info Chips (Numero, Date, Horaire, Total Arrets)
                Expanded(
                  child: _buildCompactInfoChip(
                    icon: Icons.tag_rounded,
                    value: _headerControllers['numero']?.text ?? 'N/A',
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCompactInfoChip(
                    icon: Icons.calendar_today_rounded,
                    value: _headerControllers['date']?.text ?? '',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCompactInfoChip(
                    icon: Icons.access_time_rounded,
                    value: _headerControllers['horaire']?.text ?? '',
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCompactInfoChip(
                    icon: Icons.timer_off_rounded,
                    value: _headerControllers['total_arrets']?.text ?? '0 min',
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 10),
                // Editable Fields (Equipe, Conducteur, Dressage, Presse)
                Expanded(
                  child: _buildCompactEditableField(
                    controller: _headerControllers['equipe']!,
                    icon: Icons.groups_rounded,
                    hint: 'Équipe',
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCompactEditableField(
                    controller: _headerControllers['conducteur']!,
                    icon: Icons.engineering_rounded,
                    hint: 'Conducteur',
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCompactEditableField(
                    controller: _headerControllers['dressage']!,
                    icon: Icons.construction_rounded,
                    hint: 'Dressage',
                    color: const Color(0xFFF97316),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildCompactEditableField(
                    controller: _headerControllers['presse']!,
                    icon: Icons.precision_manufacturing_rounded,
                    hint: 'Presse',
                    color: const Color(0xFFEC4899),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Bottom Row: Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.inventory_2_rounded,
                    label: 'Lots',
                    value: '${_productionControllers.length}',
                    gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.scale_rounded,
                    label: 'Brut (Kg)',
                    value: _calculateTotalBrut().toStringAsFixed(1),
                    gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Net (Kg)',
                    value: _calculateTotalNet().toStringAsFixed(1),
                    gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.trending_down_rounded,
                    label: 'Chutes',
                    value: '${_calculateAverageChutes().toStringAsFixed(1)}%',
                    gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildMiniStatCard(
                    icon: Icons.pause_circle_rounded,
                    label: 'Arrêts',
                    value: '${_arretControllers.length}',
                    gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEditableField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color color,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                bottomLeft: Radius.circular(9),
              ),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => setState(() => _hasUnsavedChanges = true),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.9),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isPrimary = false,
  }) {
    final isDisabled = onPressed == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: !isDisabled && isPrimary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.85)],
                  )
                : null,
            color: isDisabled
                ? Colors.grey.shade400
                : (!isPrimary ? color : null),
            borderRadius: BorderRadius.circular(8),
            boxShadow: !isDisabled
                ? [
                    BoxShadow(
                      color: (isPrimary ? color : Colors.black).withValues(
                        alpha: 0.2,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              else
                Icon(
                  icon,
                  size: 18,
                  color: isDisabled ? Colors.grey.shade600 : textColor,
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDisabled ? Colors.grey.shade600 : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCulotSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isCulotExpanded = !_isCulotExpanded),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00695C), Color(0xFF00897B)],
                ),
                borderRadius: _isCulotExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      )
                    : BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.science_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Section Culot',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isCulotExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isCulotExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildCulotField('par_NC', 'Par NC'),
                  _buildCulotField('culot', 'Culot'),
                  _buildCulotField('Bag', 'Bag'),
                  _buildCulotField('FO', 'FO'),
                  _buildCulotField('retour_F', 'Retour F'),
                  _buildCulotField('POID_DECHET', 'Poids Déchet'),
                  _buildCulotField('total', 'Total'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCulotField(String key, String label) {
    final isTotal = key == 'total';

    return SizedBox(
      width: 150,
      child: TextFormField(
        controller: _culotControllers[key],
        readOnly: isTotal,
        enabled: !isTotal,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: isTotal
            ? null
            : (_) {
                setState(() {
                  _hasUnsavedChanges = true;
                });
                _calculateCulotTotal();
              },
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: isTotal ? Colors.grey.shade200 : Colors.grey.shade50,
          suffixIcon: isTotal
              ? const Icon(Icons.calculate, size: 18, color: Colors.grey)
              : null,
        ),
        style: TextStyle(
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? Colors.grey.shade700 : null,
        ),
      ),
    );
  }

  Widget _buildProductionTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1,
          color: Colors.black.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.factory_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Données de production',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      // Action Buttons Group
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Add Button
                            _buildHeaderActionButton(
                              icon: Icons.add_rounded,
                              label: 'Ajouter',
                              color: Colors.white,
                              textColor: const Color(0xFF1E3A8A),
                              onPressed: _addProductionEntry,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 1,
                              height: 28,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 8),
                            // Return Button (Back without modifications)
                            _buildHeaderActionButton(
                              icon: Icons.arrow_back_rounded,
                              label: 'Retour',
                              color: const Color(0xFFE3F2FD),
                              textColor: const Color(0xFF1565C0),
                              onPressed: () => _handleBack(),
                            ),
                            const SizedBox(width: 8),
                            // Cancel Button
                            _buildHeaderActionButton(
                              icon: Icons.close_rounded,
                              label: 'Annuler',
                              color: const Color(0xFFFFCDD2),
                              textColor: const Color(0xFFC62828),
                              onPressed: () => _handleCancel(),
                            ),
                            const SizedBox(width: 8),
                            // Save Button
                            _buildHeaderActionButton(
                              icon: Icons.save_rounded,
                              label: _isSaving ? 'Saving...' : 'Enregistrer',
                              color: const Color(0xFF10B981),
                              textColor: Colors.white,
                              onPressed: _isSaving ? null : _saveFiche,
                              isLoading: _isSaving,
                              isPrimary: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Scrollbar(
                  controller: _productionHeaderScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  thickness: 8,
                  radius: const Radius.circular(4),
                  child: SingleChildScrollView(
                    controller: _productionHeaderScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Nbr Éclats',
                            width: 100,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Réf',
                            width: 150,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Produit',
                            width: 150,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Ind',
                            width: 70,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Nbr Blocs',
                            width: 100,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Lg Blocs (cm)',
                            width: 110,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'N° Lot',
                            width: 120,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Vitesse',
                            width: 90,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Pression',
                            width: 90,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Nbr Barres',
                            width: 100,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Long',
                            width: 90,
                          ),

                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Long Éclat',
                            width: 100,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Étirage (Kg)',
                            width: 110,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Nbr B. Chutes',
                            width: 120,
                          ),

                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Observation',
                            width: 200,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Actions',
                            width: 200,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'H.Début',
                            width: 90,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'H.Fin',
                            width: 90,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'P.Barre',
                            width: 90,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Coût (DH)',
                            width: 90,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Brut (Kg)',
                            width: 100,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Net (Kg)',
                            width: 100,
                          ),
                          ExtrusionEditWidgets.buildTableHeaderFixed(
                            'Taux (%)',
                            width: 90,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _productionRowsScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8,
              radius: const Radius.circular(4),
              child: SingleChildScrollView(
                controller: _productionRowsScrollController,
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: List.generate(
                      _productionControllers.length,
                      (index) => _buildProductionRowContent(index),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionRowContent(int index) {
    final controllers = _productionControllers[index];
    final isEven = index % 2 == 0;
    final isSaved = _isProductionEntrySaved(index);
    final isEditing = _editingIndices.contains(index);
    final isSaving = _savingIndices.contains(index);
    final currentStatus = controllers['status']!.text;
    final isCompleted = currentStatus == 'completed';
    final isValid = _isProductionEntryValid(index);
    // Fields are read-only only if:
    // - Item is saved AND
    // - Not in editing mode
    // Otherwise, fields are editable (when not saved yet OR when in editing mode)
    final isReadOnly = isSaved && !isEditing;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFF5F5F5),
        // Only use borderRadius when borders are uniform (not editing)
        borderRadius: isEditing ? null : BorderRadius.circular(8),
        border: isEditing
            ? Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                left: const BorderSide(color: Color(0xFF2196F3), width: 3),
                top: BorderSide(color: Colors.grey.shade200, width: 1),
                right: BorderSide(color: Colors.grey.shade200, width: 1),
              )
            : Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: isEditing
            ? [
                BoxShadow(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          _buildTableCellFixed(
            controllers['nbr_eclt']!,
            width: 100,
            isNumber: false, // Text field, not number
            isRequired: true,
            isReadOnly: isReadOnly,
          ),
          // Ref dropdown - searchable with auto-fill product_name
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _isLoadingArticles
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : SearchableDropdownT<Map<String, dynamic>>(
                      items: _articles,
                      displayText: (article) => article['ref_code'] ?? '',
                      selectedValue: _articles
                          .cast<Map<String, dynamic>?>()
                          .firstWhere(
                            (a) => a?['ref_code'] == controllers['ref']?.text,
                            orElse: () => null,
                          ),
                      onChanged: isReadOnly
                          ? null
                          : (selectedArticle) {
                              setState(() {
                                _hasUnsavedChanges = true;
                                if (selectedArticle != null) {
                                  controllers['ref']?.text =
                                      selectedArticle['ref_code'] ?? '';
                                  // Auto-fill product_name
                                  controllers['product_name']?.text =
                                      selectedArticle['product_name'] ?? '';
                                  // Auto-fill p_barre_reel from Poids
                                  final poids = selectedArticle['Poids'];
                                  controllers['p_barre_reel']?.text =
                                      poids != null ? poids.toString() : '';
                                  // Recalculate production values
                                  _calculateProduction(
                                    _productionControllers.indexOf(controllers),
                                  );
                                } else {
                                  controllers['ref']?.text = '';
                                  controllers['product_name']?.text = '';
                                  controllers['p_barre_reel']?.text = '';
                                }
                              });
                            },
                      hintText: 'Réf...',
                      searchHint: 'Chercher...',
                      noResultsText: 'Aucun article',
                      loadingText: 'Chargement...',
                      isLoading: _isLoadingArticles,
                      enabled: !isReadOnly,
                      primaryColor: const Color(0xFF2196F3),
                    ),
            ),
          ),
          // Product name - Read-only, auto-filled from ref selection
          _buildTableCellFixed(
            controllers['product_name']!,
            width: 150,
            isReadOnly: true, // Always read-only
            isCalculated: true, // Visual indicator that it's auto-filled
          ),
          _buildTableCellFixed(
            controllers['ind']!,
            width: 70,
            isRequired: true,
            isReadOnly: isReadOnly,
          ),
          _buildTableCellFixed(
            controllers['nbr_blocs']!,
            width: 100,
            isNumber: true,
            isRequired: true,
            onChanged: () => _calculateProduction(index),
            isReadOnly: isReadOnly,
          ),
          _buildTableCellFixed(
            controllers['Lg_blocs']!,
            width: 110,
            isNumber: true,
            isRequired: true,
            onChanged: () => _calculateProduction(index),
            isReadOnly: isReadOnly,
          ),
          _buildTableCellFixed(
            controllers['num_lot_billette']!,
            width: 120,
            isRequired: true,
            isReadOnly: isReadOnly,
          ),
          _buildTableCellFixed(
            controllers['vitesse']!,
            width: 90,
            isNumber: true,
            isRequired: true,
            isReadOnly: isReadOnly,
          ),
          _buildTableCellFixed(
            controllers['pres_extru']!,
            width: 90,
            isNumber: true,
            isRequired: true,
            isReadOnly: isReadOnly,
          ),
          _buildTableCellFixed(
            controllers['nbr_barres']!,
            width: 100,
            isNumber: true,
            isRequired: true,
            onChanged: () => _calculateProduction(index),
            isReadOnly: isReadOnly,
          ),
          _buildTableCellFixed(
            controllers['long']!,
            width: 90,
            isNumber: true,
            isRequired: true,
            isReadOnly: isReadOnly,
          ),
          // anass
          _buildTableCellFixed(
            controllers['Long_eclt']!,
            width: 100,
            isNumber: true,
            isRequired: false,
            isReadOnly: isReadOnly,
          ),
          _buildTableCellFixed(
            controllers['etirage_kg']!,
            width: 110,
            isNumber: true,
            isRequired: false,
            isReadOnly: isReadOnly,
          ),
          _buildTableCellFixed(
            controllers['nbr_barres_chutes']!,
            width: 120,
            isNumber: true,
            isRequired: false,
            isReadOnly: isReadOnly,
          ),
          _buildTableCellFixed(
            controllers['observation']!,
            width: 200,
            isReadOnly: isReadOnly,
          ),
          SizedBox(
            width: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Save button - only show if not saved (and valid) or in edit mode (and valid)
                if ((!isSaved && isValid) || (isEditing && isValid))
                  ExtrusionEditWidgets.buildActionIcon(
                    icon: isSaving ? Icons.hourglass_empty : Icons.save,
                    color: isSaving ? Colors.grey : _ActionColors.save,
                    onTap: isSaving ? () {} : () => _saveProductionRow(index),
                    tooltip: isSaving ? 'Enregistrement...' : 'Enregistrer',
                    isDisabled: isSaving,
                  ),
                const SizedBox(width: 3),
                // Edit button - only show if saved and not editing and not completed
                if (isSaved && !isEditing && !isCompleted)
                  ExtrusionEditWidgets.buildActionIcon(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF9C27B0),
                    onTap: () => _toggleEditMode(index),
                    tooltip: 'Modifier',
                  ),
                const SizedBox(width: 3),
                // Delete button - only show if not completed
                if (!isCompleted)
                  ExtrusionEditWidgets.buildActionIcon(
                    icon: Icons.delete_outline,
                    color: _ActionColors.delete,
                    onTap: () => _removeProductionEntry(index),
                    tooltip: 'Supprimer',
                  ),
                const SizedBox(width: 3),
                // Status chip - only show if saved
                if (isSaved)
                  Expanded(
                    child: ExtrusionEditWidgets.buildStatusChip(
                      isCompleted: isCompleted,
                      onTap: () => _toggleItemStatus(index),
                    ),
                  ),
              ],
            ),
          ),

          _buildTableCellFixed(
            controllers['heur_debut']!,
            width: 90,
            isRequired: true,
            isCalculated: true,
            isReadOnly: true,
          ),
          _buildTableCellFixed(
            controllers['heur_fin']!,
            width: 90,
            isRequired: false,
            isCalculated: true,
            isReadOnly: true,
          ),
          _buildTableCellFixed(
            controllers['p_barre_reel']!,
            width: 90,
            isNumber: true,
            isRequired: true,
            isCalculated: true, // Auto-filled from Poids
            isReadOnly: true, // Always read-only
          ),
          _buildTableCellFixed(
            controllers['CU_EXTRUSION']!,
            width: 90,
            isNumber: true,
            isRequired: true,
            isCalculated: true,
            isReadOnly: true,
          ),
          _buildTableCellFixed(
            controllers['prut_kg']!,
            width: 100,
            isNumber: true,
            isCalculated: true,
            isReadOnly: true,
          ),
          _buildTableCellFixed(
            controllers['net_kg']!,
            width: 100,
            isNumber: true,
            isCalculated: true,
            isReadOnly: true,
          ),
          _buildTableCellFixed(
            controllers['taux_de_chutes']!,
            width: 90,
            isNumber: true,
            isCalculated: true,
            isReadOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTableCellFixed(
    TextEditingController controller, {
    required double width,
    bool isNumber = false,
    bool isCalculated = false,
    bool isRequired = false,
    bool isReadOnly = false,
    VoidCallback? onChanged,
  }) {
    final isDisabled = isCalculated || isReadOnly;
    const primaryColor = Color(0xFF2196F3);

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: TextFormField(
          controller: controller,
          readOnly: isDisabled,
          enabled: !isDisabled,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          onChanged: (_) {
            // Always trigger setState to update validation state and track changes
            setState(() {
              _hasUnsavedChanges = true;
            });
            // Call additional onChanged callback if provided
            if (onChanged != null) onChanged();
          },
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDisabled ? Colors.grey[600] : Colors.grey[800],
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isRequired && !isDisabled && controller.text.isEmpty
                    ? Colors.red.shade300
                    : Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isRequired && !isDisabled && controller.text.isEmpty
                    ? Colors.red.shade300
                    : Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: isDisabled
                ? Colors.grey[100]
                : isRequired && controller.text.isEmpty
                ? Colors.red.shade50
                : Colors.grey[50],
          ),
        ),
      ),
    );
  }

  Widget _buildArretsTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1,
          color: Colors.black.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isArretsExpanded = !_isArretsExpanded),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFE64A19), Color(0xFFF57C00)],
                ),
                borderRadius: _isArretsExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      )
                    : BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Arrêts machine',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isArretsExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _addArretEntry,
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text(
                      'Ajouter',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFF57C00),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isArretsExpanded) ...[
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFE64A19), Color(0xFFF57C00)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  ExtrusionEditWidgets.buildHeaderCell('Heure début', flex: 2),
                  ExtrusionEditWidgets.buildVerticalDivider(height: 28),
                  ExtrusionEditWidgets.buildHeaderCell('Heure fin', flex: 2),
                  ExtrusionEditWidgets.buildVerticalDivider(height: 28),
                  ExtrusionEditWidgets.buildHeaderCell('Durée', flex: 2),
                  ExtrusionEditWidgets.buildVerticalDivider(height: 28),
                  ExtrusionEditWidgets.buildHeaderCell('Cause', flex: 3),
                  ExtrusionEditWidgets.buildVerticalDivider(height: 28),
                  ExtrusionEditWidgets.buildHeaderCell(
                    'Action corrective',
                    flex: 4,
                  ),
                  ExtrusionEditWidgets.buildVerticalDivider(height: 28),
                  ExtrusionEditWidgets.buildHeaderCell('Actions', flex: 1),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _arretControllers.length,
              itemBuilder: (context, index) => _buildArretRow(index),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArretRow(int index) {
    final controllers = _arretControllers[index];
    final isEven = index % 2 == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Debut - Time Picker
          _buildTimePickerCell(
            controllers['debut']!,
            flex: 2,
            index: index,
            label: 'Début',
          ),
          // Fin - Time Picker
          _buildTimePickerCell(
            controllers['fin']!,
            flex: 2,
            index: index,
            label: 'Fin',
          ),
          // Duree - Read-only, auto-calculated
          _buildReadOnlyCell(controllers['duree']!, flex: 2),
          _buildTableCell(controllers['cause']!, flex: 3),
          _buildTableCell(controllers['action']!, flex: 4),
          Expanded(
            flex: 1,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                color: const Color(0xFFF44336),
                onPressed: () => _removeArretEntry(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerCell(
    TextEditingController controller, {
    required int flex,
    required int index,
    required String label,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: () => _showTimePicker(controller, index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? label : controller.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: controller.text.isEmpty
                          ? Colors.grey.shade400
                          : const Color(0xFF263238),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyCell(
    TextEditingController controller, {
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            controller.text.isEmpty ? '-' : controller.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: controller.text.isEmpty
                  ? Colors.grey.shade400
                  : const Color(0xFF263238),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(
    TextEditingController controller, {
    int flex = 1,
    bool isNumber = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: TextFormField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF263238),
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
