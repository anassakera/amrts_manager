import '../../core/imports.dart';

class ExtrusionEditScreen extends StatefulWidget {
  final Map<String, dynamic>? fiche;
  final String? lastNumero;

  const ExtrusionEditScreen({super.key, this.fiche, this.lastNumero});

  @override
  State<ExtrusionEditScreen> createState() => _ExtrusionEditScreenState();
}

class _ExtrusionEditScreenState extends State<ExtrusionEditScreen> {
  final Map<String, TextEditingController> _headerControllers = {};
  final List<Map<String, TextEditingController>> _productionControllers = [];
  final List<Map<String, TextEditingController>> _arretControllers = [];
  Map<String, TextEditingController> _culotControllers = {};

  bool _isSaving = false;
  bool _isHeaderExpanded = false;
  bool _isArretsExpanded = false;
  bool _isCulotExpanded = false;

  // ScrollControllers for synchronized scrolling
  final ScrollController _productionHeaderScrollController = ScrollController();
  final ScrollController _productionRowsScrollController = ScrollController();

  static const List<String> _headerFieldsOrder = [
    'numero',
    'date',
    'horaire',
    'equipe',
    'conducteur',
    'dressage',
    'La_scie',
    'presse',
    'axe',
    'contenaire',
    'grain',
  ];

  static const List<String> _productionFields = [
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
    'taux_de_chutes',
    'nbr_barres_chutes',
    'observation',
  ];

  static const List<String> _arretFields = [
    'debut',
    'fin',
    'duree',
    'cause',
    'action',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupScrollSync();
  }

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
    if (widget.fiche != null) {
      source.addAll(widget.fiche!);
    }

    source['numero'] =
        source['numero'] ??
        widget.lastNumero ??
        (widget.fiche == null ? '2650' : '');
    source['date'] = source['date'] ?? defaultDate;
    source['horaire'] = source['horaire'] ?? '@8:00-16:00';

    for (final field in _headerFieldsOrder) {
      _headerControllers[field] = TextEditingController(
        text: source[field]?.toString() ?? '',
      );
    }

    final productionList =
        (source['production_data'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    if (productionList.isEmpty) {
      _productionControllers.add(_createProductionControllers({}));
    } else {
      for (final item in productionList) {
        _productionControllers.add(_createProductionControllers(item));
      }
    }

    final arretsList =
        (source['arrets'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    if (arretsList.isEmpty) {
      _arretControllers.add(_createArretControllers({}));
    } else {
      for (final item in arretsList) {
        _arretControllers.add(_createArretControllers(item));
      }
    }

    final culotMap =
        (source['culot'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    if (culotMap.isEmpty) {
      culotMap.addAll({
        'par_NC': '',
        'culot': '',
        'pag': '',
        'FO': '',
        'retour_F': '',
        'total': '',
      });
    }
    _culotControllers = {
      for (final entry in culotMap.entries)
        entry.key: TextEditingController(text: entry.value?.toString() ?? ''),
    };
  }

  Map<String, TextEditingController> _createProductionControllers(
    Map<String, dynamic> item,
  ) {
    return {
      for (final field in _productionFields)
        field: TextEditingController(text: item[field]?.toString() ?? ''),
    };
  }

  Map<String, TextEditingController> _createArretControllers(
    Map<String, dynamic> item,
  ) {
    return {
      for (final field in _arretFields)
        field: TextEditingController(text: item[field]?.toString() ?? ''),
    };
  }

  @override
  void dispose() {
    _productionHeaderScrollController.dispose();
    _productionRowsScrollController.dispose();
    for (final controller in _headerControllers.values) {
      controller.dispose();
    }
    for (final map in _productionControllers) {
      for (final controller in map.values) {
        controller.dispose();
      }
    }
    for (final map in _arretControllers) {
      for (final controller in map.values) {
        controller.dispose();
      }
    }
    for (final controller in _culotControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

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
            _buildHeaderFieldsSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartHeader() {
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF1F5F9), Color(0xFFE0E7EF)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.10),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Color(0xFF1E3A8A),
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.fiche == null
                                      ? 'Nouvelle Fiche Extrusion'
                                      : 'Modifier Fiche Extrusion',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E3A8A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.confirmation_number_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Numéro: ${_headerControllers['numero']?.text ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_pin_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _headerControllers['conducteur']
                                              ?.text
                                              .isEmpty ??
                                          true
                                      ? 'Conducteur'
                                      : _headerControllers['conducteur']!.text,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _headerControllers['date']?.text ??
                                      DateTime.now().toString().split(' ')[0],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icons.cancel_rounded,
                      label: 'Annuler',
                      color: const Color(0xFFE57373),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      onPressed: _isSaving ? null : _saveFiche,
                      icon: Icons.save_rounded,
                      label: _isSaving ? 'Enregistrement...' : 'Enregistrer',
                      color: const Color(0xFF66BB6A),
                      isLoading: _isSaving,
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const SizedBox(width: 5),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.inventory_2,
                        label: 'Nombre d\'articles',
                        value: '${_productionControllers.length}',
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.scale,
                        label: 'Poids total',
                        value:
                            '${_calculateTotalWeight().toStringAsFixed(2)} Kg',
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.assessment,
                        label: 'Nbr Arrêts',
                        value: '${_arretControllers.length}',
                        color: const Color(0xFFFF9800),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.science,
                        label: 'Section Culot',
                        value: '${_culotControllers.length} champs',
                        color: const Color(0xFF9C27B0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
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
            if (isLoading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ] else ...[
              Icon(icon, size: 20),
            ],
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

  Widget _buildInfoCard({
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

  double _calculateTotalWeight() {
    double total = 0;
    for (var controllers in _productionControllers) {
      final netKg = double.tryParse(controllers['net_kg']?.text ?? '0') ?? 0;
      total += netKg;
    }
    return total;
  }

  Widget _buildHeaderFieldsSection() {
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
            onTap: () {
              setState(() {
                _isHeaderExpanded = !_isHeaderExpanded;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                ),
                borderRadius: _isHeaderExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      )
                    : BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Informations générales',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isHeaderExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isHeaderExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildHeaderField('numero', 'Numéro', Icons.tag),
                  _buildHeaderField('date', 'Date', Icons.calendar_today),
                  _buildHeaderField('horaire', 'Horaire', Icons.access_time),
                  _buildHeaderField('equipe', 'Équipe', Icons.groups),
                  _buildHeaderField(
                    'conducteur',
                    'Conducteur',
                    Icons.engineering,
                  ),
                  _buildHeaderField('dressage', 'Dressage', Icons.construction),
                  _buildHeaderField('La_scie', 'La Scie', Icons.handyman),
                  _buildHeaderField(
                    'presse',
                    'Presse',
                    Icons.precision_manufacturing,
                  ),
                  _buildHeaderField('axe', 'Axe', Icons.terrain),
                  _buildHeaderField(
                    'contenaire',
                    'Contenaire',
                    Icons.inventory_2,
                  ),
                  _buildHeaderField('grain', 'Grain', Icons.grain),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderField(String key, String label, IconData icon) {
    return SizedBox(
      width: 200,
      child: TextFormField(
        controller: _headerControllers[key],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF8E24AA)),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF8E24AA), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
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
            onTap: () {
              setState(() {
                _isCulotExpanded = !_isCulotExpanded;
              });
            },
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
                  _buildCulotField('pag', 'PAG'),
                  _buildCulotField('FO', 'FO'),
                  _buildCulotField('retour_F', 'Retour F'),
                  _buildCulotField('total', 'Total'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCulotField(String key, String label) {
    return SizedBox(
      width: 150,
      child: TextFormField(
        controller: _culotControllers[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          filled: true,
          fillColor: Colors.grey.shade50,
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
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.factory, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Données de production',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _addProductionEntry,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text(
                          'Ajouter',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1976D2),
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
                          _buildTableHeaderFixed('Nbr Éclats', width: 100),
                          _buildTableHeaderFixed('Réf', width: 100),
                          _buildTableHeaderFixed('Ind', width: 70),
                          _buildTableHeaderFixed('H.Début', width: 90),
                          _buildTableHeaderFixed('H.Fin', width: 90),
                          _buildTableHeaderFixed('Nbr Blocs', width: 100),
                          _buildTableHeaderFixed('Lg Blocs (cm)', width: 110),
                          _buildTableHeaderFixed('Brut (Kg)', width: 100),
                          _buildTableHeaderFixed('N° Lot', width: 120),
                          _buildTableHeaderFixed('Vitesse', width: 90),
                          _buildTableHeaderFixed('Pression', width: 90),
                          _buildTableHeaderFixed('Nbr Barres', width: 100),
                          _buildTableHeaderFixed('Long', width: 90),
                          _buildTableHeaderFixed('P.Barre', width: 90),
                          _buildTableHeaderFixed('Net (Kg)', width: 100),
                          _buildTableHeaderFixed('Long Éclat', width: 100),
                          _buildTableHeaderFixed('Étirage (Kg)', width: 110),
                          _buildTableHeaderFixed('Taux (%)', width: 90),
                          _buildTableHeaderFixed('Nbr B. Chutes', width: 120),
                          _buildTableHeaderFixed('Observation', width: 200),
                          _buildTableHeaderFixed('Actions', width: 80),
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

  Widget _buildTableHeaderFixed(String title, {required double width}) {
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

  Widget _buildProductionRowContent(int index) {
    final controllers = _productionControllers[index];
    final isEven = index % 2 == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          _buildTableCellFixed(
            controllers['nbr_eclt']!,
            width: 100,
            isNumber: true,
            isRequired: true,
          ),
          _buildTableCellFixed(
            controllers['ref']!,
            width: 100,
            isRequired: true,
          ),
          _buildTableCellFixed(
            controllers['ind']!,
            width: 70,
            isRequired: true,
          ),
          _buildTableCellFixed(
            controllers['heur_debut']!,
            width: 90,
            isRequired: true,
          ),
          _buildTableCellFixed(
            controllers['heur_fin']!,
            width: 90,
            isRequired: true,
          ),
          _buildTableCellFixed(
            controllers['nbr_blocs']!,
            width: 100,
            isNumber: true,
            isRequired: true,
            onChanged: () => _calculateProduction(index),
          ),
          _buildTableCellFixed(
            controllers['Lg_blocs']!,
            width: 110,
            isNumber: true,
            isRequired: true,
            onChanged: () => _calculateProduction(index),
          ),
          _buildTableCellFixed(
            controllers['prut_kg']!,
            width: 100,
            isNumber: true,
            isCalculated: true,
          ),
          _buildTableCellFixed(
            controllers['num_lot_billette']!,
            width: 120,
            isRequired: true,
          ),
          _buildTableCellFixed(
            controllers['vitesse']!,
            width: 90,
            isNumber: true,
            isRequired: true,
          ),
          _buildTableCellFixed(
            controllers['pres_extru']!,
            width: 90,
            isNumber: true,
            isRequired: true,
          ),
          _buildTableCellFixed(
            controllers['nbr_barres']!,
            width: 100,
            isNumber: true,
            isRequired: true,
            onChanged: () => _calculateProduction(index),
          ),
          _buildTableCellFixed(
            controllers['long']!,
            width: 90,
            isNumber: true,
            isRequired: true,
          ),
          _buildTableCellFixed(
            controllers['p_barre_reel']!,
            width: 90,
            isNumber: true,
            isRequired: true,
            onChanged: () => _calculateProduction(index),
          ),
          _buildTableCellFixed(
            controllers['net_kg']!,
            width: 100,
            isNumber: true,
            isCalculated: true,
          ),
          _buildTableCellFixed(
            controllers['Long_eclt']!,
            width: 100,
            isNumber: true,
            isRequired: true,
          ),
          _buildTableCellFixed(
            controllers['etirage_kg']!,
            width: 110,
            isNumber: true,
            isRequired: true,
          ),
          _buildTableCellFixed(
            controllers['taux_de_chutes']!,
            width: 90,
            isNumber: true,
            isCalculated: true,
          ),
          _buildTableCellFixed(
            controllers['nbr_barres_chutes']!,
            width: 120,
            isNumber: true,
            isRequired: true,
          ),
          _buildTableCellFixed(controllers['observation']!, width: 200),
          SizedBox(
            width: 80,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                color: const Color(0xFFF44336),
                onPressed: () => _removeProductionEntry(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _calculateProduction(int index) {
    // anass
    final controllers = _productionControllers[index];

    final nbrBlocs = double.tryParse(controllers['nbr_blocs']!.text) ?? 0;
    final lgBlocs = double.tryParse(controllers['Lg_blocs']!.text) ?? 0;
    final brutKg = nbrBlocs * lgBlocs * 0.3;

    final nbrBarres = double.tryParse(controllers['nbr_barres']!.text) ?? 0;
    final pBarreReel = double.tryParse(controllers['p_barre_reel']!.text) ?? 0;
    final netKg = nbrBarres * pBarreReel;

    final tauxDeChutes = brutKg > 0 ? ((brutKg - netKg) / brutKg) * 100 : 0;

    setState(() {
      controllers['prut_kg']!.text = brutKg.toStringAsFixed(2);
      controllers['net_kg']!.text = netKg.toStringAsFixed(2);
      controllers['taux_de_chutes']!.text = tauxDeChutes.toStringAsFixed(2);
    });
  }

  Widget _buildTableCellFixed(
    TextEditingController controller, {
    required double width,
    bool isNumber = false,
    bool isCalculated = false,
    bool isRequired = false,
    VoidCallback? onChanged,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: TextFormField(
          controller: controller,
          readOnly: isCalculated,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          onChanged: onChanged != null ? (_) => onChanged() : null,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isCalculated
                ? Colors.grey.shade600
                : const Color(0xFF263238),
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
              borderSide: BorderSide(
                color: isRequired ? Colors.red.shade300 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isRequired && controller.text.isEmpty
                    ? Colors.red.shade300
                    : Colors.grey.shade300,
                width: isRequired && controller.text.isEmpty ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
            ),
            filled: true,
            fillColor: isCalculated ? Colors.grey.shade100 : Colors.white,
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
            onTap: () {
              setState(() {
                _isArretsExpanded = !_isArretsExpanded;
              });
            },
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
                  _buildHeaderCell('Heure début', flex: 2),
                  _verticalDivider(height: 28),
                  _buildHeaderCell('Heure fin', flex: 2),
                  _verticalDivider(height: 28),
                  _buildHeaderCell('Durée', flex: 2),
                  _verticalDivider(height: 28),
                  _buildHeaderCell('Cause', flex: 3),
                  _verticalDivider(height: 28),
                  _buildHeaderCell('Action corrective', flex: 4),
                  _verticalDivider(height: 28),
                  _buildHeaderCell('Actions', flex: 1),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _arretControllers.length,
              itemBuilder: (context, index) {
                return _buildArretRow(index);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
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
          _buildTableCell(controllers['debut']!, flex: 2),
          _buildTableCell(controllers['fin']!, flex: 2),
          _buildTableCell(controllers['duree']!, flex: 2, isNumber: true),
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

  Widget _verticalDivider({double? height}) {
    return Container(
      width: 1,
      height: height ?? double.infinity,
      color: const Color(0xFFE5E7EB),
    );
  }

  void _addProductionEntry() {
    setState(() {
      _productionControllers.add(_createProductionControllers({}));
    });
  }

  void _removeProductionEntry(int index) {
    if (_productionControllers.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez garder au moins une ligne de production'),
          backgroundColor: Color(0xFFF44336),
        ),
      );
      return;
    }
    setState(() {
      final removed = _productionControllers.removeAt(index);
      for (final controller in removed.values) {
        controller.dispose();
      }
    });
  }

  void _addArretEntry() {
    setState(() {
      _arretControllers.add(_createArretControllers({}));
    });
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
      final removed = _arretControllers.removeAt(index);
      for (final controller in removed.values) {
        controller.dispose();
      }
    });
  }

  Future<void> _saveFiche() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 400));

      final numero = _headerControllers['numero']!.text.trim();
      final fiche = <String, dynamic>{'numero': numero};
      for (final entry in _headerControllers.entries) {
        fiche[entry.key] = entry.value.text.trim();
      }

      fiche['production_data'] = _productionControllers.map((map) {
        return {
          for (final entry in map.entries) entry.key: entry.value.text.trim(),
        };
      }).toList();

      fiche['arrets'] = _arretControllers.map((map) {
        return {
          for (final entry in map.entries) entry.key: entry.value.text.trim(),
        };
      }).toList();

      fiche['culot'] = {
        for (final entry in _culotControllers.entries)
          entry.key: entry.value.text.trim(),
      };

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                widget.fiche == null
                    ? 'Fiche créée avec succès'
                    : 'Fiche mise à jour avec succès',
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, fiche);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erreur lors de l\'enregistrement: $error')),
            ],
          ),
          backgroundColor: const Color(0xFFF44336),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
