import '../../../core/imports.dart';

class PeintureEditScreen extends StatefulWidget {
  final Map<String, dynamic>? production;
  final String? lastRefPeinture;

  const PeintureEditScreen({super.key, this.production, this.lastRefPeinture});

  @override
  State<PeintureEditScreen> createState() => _PeintureEditScreenState();
}

class _PeintureEditScreenState extends State<PeintureEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _items = [];
  final List<int> _selectedIndices = [];
  bool _isSaving = false;
  int? _editingIndex;
  bool get _hasSelection => _selectedIndices.isNotEmpty;
  String _currentItemStatus = 'completed';

  final Map<String, TextEditingController> _itemControllers = {};

  String _refPeinture = '';
  String _date = '';
  String _time = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeControllers();
  }

  void _initializeData() {
    final now = DateTime.now();

    final formattedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    _items.clear();

    if (widget.production != null) {
      final production = Map<String, dynamic>.from(widget.production!);
      _refPeinture =
          production['ref_peinture']?.toString() ??
          _computeNextRef(widget.lastRefPeinture, now);

      final incomingItems =
          (production['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _items.addAll(
        incomingItems.map((item) => Map<String, dynamic>.from(item)),
      );

      if (_items.isNotEmpty) {
        final lastItem = _items.last;
        _date = lastItem['date']?.toString() ?? formattedDate;
        _time = lastItem['time']?.toString() ?? formattedTime;
      } else {
        _date = formattedDate;
        _time = formattedTime;
      }
    } else {
      _refPeinture = _computeNextRef(widget.lastRefPeinture, now);
      _date = formattedDate;
      _time = formattedTime;
    }
  }

  String _computeNextRef(String? lastRef, DateTime now) {
    final reg = RegExp(r'^PE-(\d{2})-(\d{2})-(\d{5})$');
    if (lastRef != null) {
      final m = reg.firstMatch(lastRef);
      if (m != null) {
        final lastYY = m.group(1)!;
        final lastMM = m.group(2)!;
        final lastSeq = int.tryParse(m.group(3)!) ?? 0;
        final next = (lastSeq + 1).toString().padLeft(5, '0');
        return 'PE-$lastYY-$lastMM-$next';
      }
    }
    final yy = now.year.toString().substring(2);
    final mm = now.month.toString().padLeft(2, '0');
    return 'PE-$yy-$mm-00001';
  }

  void _initializeControllers() {
    _itemControllers['ref'] = TextEditingController();
    _itemControllers['designations'] = TextEditingController();
    _itemControllers['qte'] = TextEditingController();
    _itemControllers['poid_barre'] = TextEditingController();
    _itemControllers['poid'] = TextEditingController();
    _itemControllers['dichet'] = TextEditingController();
    _itemControllers['poid_net'] = TextEditingController();
    _itemControllers['couleur'] = TextEditingController();
    _itemControllers['cout_production_unitaire'] = TextEditingController();
    _itemControllers['prix_vente'] = TextEditingController();
    _itemControllers['type'] = TextEditingController();
    _itemControllers['date'] = TextEditingController();
  }

  void _clearControllers() {
    _itemControllers.forEach((key, controller) {
      controller.clear();
    });
  }

  void _loadItemToControllers(Map<String, dynamic> item) {
    _itemControllers['ref']?.text = item['ref']?.toString() ?? '';
    _itemControllers['designations']?.text =
        item['designations']?.toString() ?? '';
    _itemControllers['qte']?.text = item['qte']?.toString() ?? '';
    _itemControllers['poid_barre']?.text = item['poid_barre']?.toString() ?? '';
    _itemControllers['poid']?.text = item['poid']?.toString() ?? '';
    _itemControllers['dichet']?.text = item['dichet']?.toString() ?? '';
    _itemControllers['poid_net']?.text = item['poid_net']?.toString() ?? '';
    _itemControllers['couleur']?.text = item['couleur']?.toString() ?? '';
    _itemControllers['cout_production_unitaire']?.text =
        item['cout_production_unitaire']?.toString() ?? '';
    _itemControllers['prix_vente']?.text = item['prix_vente']?.toString() ?? '';
    _itemControllers['type']?.text = item['type']?.toString() ?? '';
    _itemControllers['date']?.text = item['date']?.toString() ?? '';
  }

  double _calculateTotalPoid() {
    double total = 0;
    for (var item in _items) {
      total += (item['poid'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _calculateTotalDichet() {
    double total = 0;
    for (var item in _items) {
      total += (item['dichet'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _calculateTotalPoidNet() {
    double total = 0;
    for (var item in _items) {
      total += (item['poid_net'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _calculateTotalCout() {
    double total = 0;
    for (var item in _items) {
      final qte = (item['qte'] as num?)?.toDouble() ?? 0;
      final cout = (item['cout_production_unitaire'] as num?)?.toDouble() ?? 0;
      total += qte * cout;
    }
    return total;
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(2);
  }

  int _getLocalNextItemId() {
    if (_items.isEmpty) {
      return 1;
    }
    final maxId = _items.fold<int>(0, (prev, item) {
      final id = item['id'] as int? ?? 0;
      return id > prev ? id : prev;
    });
    return maxId + 1;
  }

  @override
  void dispose() {
    _itemControllers.forEach((key, controller) {
      controller.dispose();
    });
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
            Expanded(child: _buildSmartTable()),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartHeader() {
    final itemsCount = _items.length;

    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                                  Icons.format_paint_rounded,
                                  color: Color(0xFF1E3A8A),
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.production == null
                                      ? 'Nouvelle Production Peinture'
                                      : 'Modifier Production Peinture',
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
                                  Icons.qr_code_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Référence: $_refPeinture',
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
                                  Icons.calendar_month_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _date,
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icons.cancel_rounded,
                      label: 'Annuler',
                      color: const Color(0xFFE57373),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      onPressed: _isSaving ? null : _saveProduction,
                      icon: Icons.save_rounded,
                      label: _isSaving ? 'Enregistrement...' : 'Enregistrer',
                      color: const Color(0xFF66BB6A),
                      isLoading: _isSaving,
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.list_alt,
                          label: 'Nombre d\'opérations',
                          value: itemsCount.toString(),
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.scale,
                          label: 'Poids Total',
                          value: _formatNumber(_calculateTotalPoid()),
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.delete_outline,
                          label: 'Déchet',
                          value: _formatNumber(_calculateTotalDichet()),
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.balance,
                          label: 'Poids Net',
                          value: _formatNumber(_calculateTotalPoidNet()),
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.attach_money,
                          label: 'Coût Total',
                          value: '${_formatNumber(_calculateTotalCout())} DH',
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF64748B,
                                ).withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildTooltipButton(
                                  tooltip: 'Sélectionner tout',
                                  onTap: _selectAll,
                                  icon: Icons.select_all_rounded,
                                  color: const Color(0xFF8B5CF6),
                                ),
                                _buildTooltipButton(
                                  tooltip: 'Ajouter nouveau',
                                  onTap: _addNewItem,
                                  icon: Icons.add_circle_outline_rounded,
                                  color: const Color(0xFF10B981),
                                ),
                                if (_hasSelection)
                                  _buildTooltipButton(
                                    tooltip: 'Supprimer sélection',
                                    onTap: _deleteSelected,
                                    icon: Icons.delete_sweep_rounded,
                                    color: const Color(0xFFEF4444),
                                  ),
                                if (_hasSelection)
                                  _buildTooltipButton(
                                    tooltip: 'Effacer sélection',
                                    onTap: _clearSelection,
                                    icon: Icons.clear_all_rounded,
                                    color: const Color(0xFF6B7280),
                                  ),
                              ],
                            ),
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
      ),
    );
  }

  Future<void> _saveProduction() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins une opération avant de sauvegarder.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.production == null
                ? 'Production créée avec succès'
                : 'Production mise à jour avec succès',
          ),
          backgroundColor: Colors.green.shade600,
        ),
      );

      int nextId = _getLocalNextItemId();
      final normalizedItems = <Map<String, dynamic>>[];
      for (final item in _items) {
        final newItem = Map<String, dynamic>.from(item);
        newItem['status'] = newItem['status'] ?? 'completed';
        if (newItem['id'] == null) {
          newItem['id'] = nextId;
          nextId += 1;
        }
        normalizedItems.add(newItem);
      }

      final totalQuantity = normalizedItems.fold<int>(
        0,
        (prev, item) => prev + (item['qte'] as int? ?? 0),
      );
      final totalCout = normalizedItems.fold<double>(
        0,
        (prev, item) =>
            prev +
            ((item['cout_production_unitaire'] as num? ?? 0).toDouble() *
                (item['qte'] as num? ?? 0).toDouble()),
      );

      Navigator.pop(context, {
        'ref_peinture': _refPeinture,
        'total_quantity': totalQuantity,
        'total_cout': totalCout,
        'operations_count': normalizedItems.length,
        'items': normalizedItems,
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $error'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _addNewItem() {
    setState(() {
      _editingIndex = _items.length;
      _clearControllers();
      _itemControllers['date']?.text = DateTime.now().toString().split(' ')[0];
      _currentItemStatus = 'completed';
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIndices.clear();
      for (int i = 0; i < _items.length; i++) {
        _selectedIndices.add(i);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndices.clear();
    });
  }

  void _deleteSelected() {
    if (_selectedIndices.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${_selectedIndices.length} élément(s) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedIndices.sort((a, b) => b.compareTo(a));
                for (var index in _selectedIndices) {
                  if (index >= 0 && index < _items.length) {
                    _items.removeAt(index);
                  }
                }
                _selectedIndices.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Éléments supprimés avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _editItem(int index) {
    setState(() {
      _editingIndex = index;
      final item = _items[index];
      _loadItemToControllers(item);
      _currentItemStatus = item['status']?.toString() ?? 'completed';
    });
  }

  void _saveItem() {
    if (_formKey.currentState?.validate() ?? false) {
      final isEditing = _editingIndex != null && _editingIndex! < _items.length;
      final existingId = isEditing
          ? _items[_editingIndex!]['id'] as int?
          : null;

      final newItem = <String, dynamic>{
        'id': existingId ?? _getLocalNextItemId(),
        'ref': _itemControllers['ref']?.text.trim() ?? '',
        'designations': _itemControllers['designations']?.text.trim() ?? '',
        'qte': int.tryParse(_itemControllers['qte']?.text.trim() ?? '0') ?? 0,
        'poid_barre':
            double.tryParse(
              _itemControllers['poid_barre']?.text.replaceAll(',', '.') ?? '0',
            ) ??
            0.0,
        'poid':
            double.tryParse(
              _itemControllers['poid']?.text.replaceAll(',', '.') ?? '0',
            ) ??
            0.0,
        'dichet':
            double.tryParse(
              _itemControllers['dichet']?.text.replaceAll(',', '.') ?? '0',
            ) ??
            0.0,
        'poid_net':
            double.tryParse(
              _itemControllers['poid_net']?.text.replaceAll(',', '.') ?? '0',
            ) ??
            0.0,
        'couleur': _itemControllers['couleur']?.text.trim() ?? '',
        'cout_production_unitaire':
            double.tryParse(
              _itemControllers['cout_production_unitaire']?.text.replaceAll(
                    ',',
                    '.',
                  ) ??
                  '0',
            ) ??
            0.0,
        'prix_vente':
            double.tryParse(
              _itemControllers['prix_vente']?.text.replaceAll(',', '.') ?? '0',
            ) ??
            0.0,
        'type': _itemControllers['type']?.text.trim() ?? '',
        'date': _itemControllers['date']?.text.isNotEmpty == true
            ? _itemControllers['date']!.text
            : DateTime.now().toString().split(' ')[0],
        'time': _time,
        'status': _currentItemStatus,
      };

      setState(() {
        if (isEditing) {
          _items[_editingIndex!] = newItem;
        } else {
          _items.add(newItem);
        }
        _editingIndex = null;
        _clearControllers();
        _currentItemStatus = 'completed';
        _date = newItem['date']?.toString() ?? _date;
        _time = newItem['time']?.toString() ?? _time;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Article enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _clearControllers();
      _currentItemStatus = 'completed';
    });
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous supprimer cet article ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (index >= 0 && index < _items.length) {
                  _items.removeAt(index);
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Article supprimé avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartTable() {
    final isAddingNew = _editingIndex != null && _editingIndex == _items.length;
    final itemCount = _items.length + (isAddingNew ? 1 : 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1,
          color: Colors.black.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: itemCount == 0
                ? _buildEmptyTable()
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (isAddingNew && index == 0) {
                        return _buildEditRow(_items.length);
                      } else {
                        final actualIndex = isAddingNew ? index - 1 : index;
                        return _buildTableRow(_items[actualIndex], actualIndex);
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTable() {
    return Center(
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
            'Aucun élément',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cliquez sur "Ajouter nouveau" pour ajouter un élément',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          const SizedBox(width: 30),
          _buildHeaderCell('Réf', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Désignation', flex: 2),
          _verticalDivider(height: 28),
          _buildHeaderCell('Qté', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('P.Barre', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Poids', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Déchet', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('P.Net', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Couleur', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Coût U.', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('P.Vente', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Type', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Date', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Statut', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Actions', flex: 1),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item, int index) {
    final isSelected = _selectedIndices.contains(index);
    final isEditing = _editingIndex == index;

    if (isEditing) {
      return _buildEditRow(index);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF60A5FA).withValues(alpha: 0.13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: const Color(0xFF3B82F6), width: 2)
            : null,
      ),
      child: InkWell(
        onTap: () => _toggleSelection(index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              InkWell(
                onTap: () => _toggleSelection(index),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E3A8A)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFF60A5FA),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              _buildDataCell(item['ref']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['designations']?.toString() ?? '', flex: 2),
              _verticalDivider(height: 28),
              _buildDataCell(item['qte']?.toString() ?? '0', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(
                _formatNumber((item['poid_barre'] as num?)?.toDouble() ?? 0),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _formatNumber((item['poid'] as num?)?.toDouble() ?? 0),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _formatNumber((item['dichet'] as num?)?.toDouble() ?? 0),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _formatNumber((item['poid_net'] as num?)?.toDouble() ?? 0),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(item['couleur']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(
                _formatNumber(
                  (item['cout_production_unitaire'] as num?)?.toDouble() ?? 0,
                ),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _formatNumber((item['prix_vente'] as num?)?.toDouble() ?? 0),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(item['type']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['date']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.center,
                  child: _buildStatusChip(
                    (item['status'] ?? 'completed').toString(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionIconButton(
                      icon: Icons.edit,
                      onPressed: () => _editItem(index),
                      color: const Color(0xFF3B82F6),
                    ),
                    _buildActionIconButton(
                      icon: Icons.delete_outline,
                      onPressed: () => _deleteItem(index),
                      color: Colors.red.shade400,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditRow(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF60A5FA).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6), width: 2),
      ),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            const SizedBox(width: 20),
            _buildEditField('ref', 'Réf', flex: 1),
            _verticalDivider(height: 28),
            _buildEditField('designations', 'Désignation', flex: 2),
            _verticalDivider(height: 28),
            _buildEditField('qte', 'Qté', flex: 1, isNumber: true),
            _verticalDivider(height: 28),
            _buildEditField(
              'poid_barre',
              'P.Barre',
              flex: 1,
              isNumber: true,
              isDecimal: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'poid',
              'Poids',
              flex: 1,
              isNumber: true,
              isDecimal: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'dichet',
              'Déchet',
              flex: 1,
              isNumber: true,
              isDecimal: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'poid_net',
              'P.Net',
              flex: 1,
              isNumber: true,
              isDecimal: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField('couleur', 'Couleur', flex: 1),
            _verticalDivider(height: 28),
            _buildEditField(
              'cout_production_unitaire',
              'Coût U.',
              flex: 1,
              isNumber: true,
              isDecimal: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'prix_vente',
              'P.Vente',
              flex: 1,
              isNumber: true,
              isDecimal: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField('type', 'Type', flex: 1),
            _verticalDivider(height: 28),
            _buildEditField('date', 'Date', flex: 1, isReadOnly: true),
            _verticalDivider(height: 28),
            _buildStatusDropdown(),
            const SizedBox(width: 30),
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  _buildActionIconButton(
                    icon: Icons.save,
                    onPressed: _saveItem,
                    color: const Color(0xFF1E3A8A),
                  ),
                  _buildActionIconButton(
                    icon: Icons.close,
                    onPressed: _cancelEdit,
                    color: Colors.red.shade400,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 30),
          ],
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

  Widget _buildTooltipButton({
    required String tooltip,
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
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

  Widget _buildDataCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return IconButton(
      icon: Icon(icon, size: 16, color: color),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  Widget _buildEditField(
    String key,
    String hint, {
    int flex = 1,
    bool isNumber = false,
    bool isDecimal = false,
    bool isReadOnly = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: _itemControllers[key],
            readOnly: isReadOnly,
            keyboardType: isNumber
                ? (isDecimal
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number)
                : TextInputType.text,
            style: TextStyle(
              fontSize: 16,
              color: isReadOnly ? Colors.grey.shade600 : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            validator: (value) {
              if (!isReadOnly && (value == null || value.isEmpty)) {
                return 'Requis';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.blueAccent,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 5,
              ),
              filled: true,
              fillColor: isReadOnly ? Colors.grey.shade100 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    const statuses = ['completed', 'in_progress', 'pending', 'cancelled'];

    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _currentItemStatus,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.white,
              hintText: 'Statut',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.blueAccent,
                  width: 2,
                ),
              ),
            ),
            items: statuses
                .map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentItemStatus = value;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'in_progress':
        return const Color(0xFFF59E0B);
      case 'pending':
        return const Color(0xFF2563EB);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _verticalDivider({double? height}) {
    return Container(
      width: 1,
      height: height ?? double.infinity,
      color: const Color(0xFFE5E7EB),
    );
  }
}
