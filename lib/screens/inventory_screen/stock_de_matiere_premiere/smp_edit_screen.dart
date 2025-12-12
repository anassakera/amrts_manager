import '../../../core/imports.dart';

class SmpEditScreen extends StatefulWidget {
  final Map<String, dynamic>? stock;
  final String? lastRefCode;

  const SmpEditScreen({super.key, this.stock, this.lastRefCode});

  @override
  State<SmpEditScreen> createState() => _SmpEditScreenState();
}

class _SmpEditScreenState extends State<SmpEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _items = [];
  final List<int> _selectedIndices = [];
  bool _isSaving = false;
  int? _editingIndex;
  bool get _hasSelection => _selectedIndices.isNotEmpty;
  String _currentItemStatus = 'Disponible';
  String _stockStatus = 'Disponible';

  final Map<String, TextEditingController> _itemControllers = {};

  String _refCode = '';
  String _date = '';

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

    _items.clear();

    if (widget.stock != null) {
      final stock = Map<String, dynamic>.from(widget.stock!);
      _refCode =
          stock['ref_code']?.toString() ?? _computeNextRef(widget.lastRefCode);
      _stockStatus = stock['status']?.toString() ?? 'Disponible';

      // التنسيق الجديد: العمليات في 'inventory_smp_operations'
      final incomingItems =
          (stock['inventory_smp_operations'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          (stock['operations'] as List?)?.cast<Map<String, dynamic>>() ??
          (stock['items'] as List?)?.cast<Map<String, dynamic>>() ??
          [];

      _items.addAll(
        incomingItems.map((item) => Map<String, dynamic>.from(item)),
      );

      if (_items.isNotEmpty) {
        final lastItem = _items.last;
        final dateValue = lastItem['date'];

        if (dateValue != null) {
          try {
            if (dateValue is Map) {
              final dateStr = dateValue['date']?.toString() ?? '';
              if (dateStr.isNotEmpty) {
                final dateTime = DateTime.parse(dateStr.split('.').first);
                _date =
                    '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
              } else {
                _date = formattedDate;
              }
            } else {
              final dateStr = dateValue.toString();
              if (dateStr.contains(' ')) {
                _date = dateStr.split(' ').first;
              } else {
                _date = dateStr;
              }
            }
          } catch (e) {
            _date = formattedDate;
          }
        } else {
          _date = formattedDate;
        }
      } else {
        _date = formattedDate;
      }
    } else {
      _refCode = _computeNextRef(widget.lastRefCode);
      _date = formattedDate;
    }
  }

  String _computeNextRef(String? lastRef) {
    final reg = RegExp(r'^REF(\d{3})$');
    if (lastRef != null) {
      final m = reg.firstMatch(lastRef);
      if (m != null) {
        final lastSeq = int.tryParse(m.group(1)!) ?? 0;
        final next = (lastSeq + 1).toString().padLeft(3, '0');
        return 'REF$next';
      }
    }
    return 'REF001';
  }

  void _initializeControllers() {
    _itemControllers['date'] = TextEditingController();
    _itemControllers['n_facture'] = TextEditingController();
    _itemControllers['fournisseur'] = TextEditingController();
    _itemControllers['ref_code'] = TextEditingController();
    _itemControllers['material_name'] = TextEditingController();
    _itemControllers['quantite'] = TextEditingController();
    _itemControllers['prix_u'] = TextEditingController();
    _itemControllers['unite'] = TextEditingController();
    _itemControllers['total_amount'] = TextEditingController();
    _itemControllers['categorie'] = TextEditingController();
    _itemControllers['source_ref'] = TextEditingController();

    // إضافة listeners لتحديث الحساب التلقائي
    _itemControllers['quantite']?.addListener(() {
      setState(() {});
    });
    _itemControllers['prix_u']?.addListener(() {
      setState(() {});
    });
  }

  void _clearControllers() {
    _itemControllers.forEach((key, controller) {
      controller.clear();
    });
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (var item in _items) {
      total += (item['total_amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _calculateTotalQuantity() {
    double total = 0;
    for (var item in _items) {
      final quantity = item['quantite'];
      if (quantity is int) {
        total += quantity.toDouble();
      } else if (quantity is double) {
        total += quantity;
      } else if (quantity is String) {
        total += double.tryParse(quantity) ?? 0.0;
      }
    }
    return total;
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(2);
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '';

    try {
      // إذا كانت القيمة Map (من قاعدة البيانات)
      if (dateValue is Map) {
        final dateStr = dateValue['date']?.toString() ?? '';
        if (dateStr.isEmpty) return '';

        final dateTime = DateTime.parse(dateStr.split('.').first);
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} (${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')})';
      }

      // إذا كانت القيمة String
      final dateStr = dateValue.toString();

      // إذا كان التاريخ بتنسيق YYYY-MM-DD فقط
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
        return dateStr;
      }

      // إذا كان التاريخ يحتوي على وقت
      if (dateStr.contains(' ')) {
        final dateTime = DateTime.parse(dateStr.split('.').first);
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} (${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')})';
      }

      return dateStr;
    } catch (e) {
      return dateValue.toString();
    }
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
                                  Icons.inventory_2_rounded,
                                  color: Color(0xFF1E3A8A),
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.stock == null
                                      ? 'Nouveau Stock Matière Première'
                                      : 'Modifier Stock Matière Première',
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
                                  'Référence: $_refCode',
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
                                  _formatDate(_date),
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
                      onPressed: _isSaving ? null : _saveStock,
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
                          icon: Icons.production_quantity_limits,
                          label: 'Quantité Totale',
                          value:
                              '${_formatNumber(_calculateTotalQuantity())} KG',
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.attach_money,
                          label: 'Montant Total',
                          value: '${_formatNumber(_calculateTotalAmount())} DH',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(child: _buildStockStatusDropdown()),
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

  Future<void> _saveStock() async {
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
            widget.stock == null
                ? 'Stock créé avec succès'
                : 'Stock mis à jour avec succès',
          ),
          backgroundColor: Colors.green.shade600,
        ),
      );

      int nextId = _getLocalNextItemId();
      final normalizedItems = <Map<String, dynamic>>[];
      for (final item in _items) {
        final newItem = Map<String, dynamic>.from(item);
        newItem['status'] = newItem['status'] ?? 'Disponible';
        if (newItem['id'] == null) {
          newItem['id'] = nextId;
          nextId += 1;
        }
        normalizedItems.add(newItem);
      }

      final totalQuantity = normalizedItems.fold<double>(0.0, (prev, item) {
        final quantity = item['quantite'];
        if (quantity is int) {
          return prev + quantity.toDouble();
        } else if (quantity is double) {
          return prev + quantity;
        } else if (quantity is String) {
          return prev + (double.tryParse(quantity) ?? 0.0);
        }
        return prev;
      });
      final totalAmount = normalizedItems.fold<double>(
        0.0,
        (prev, item) => prev + (item['total_amount'] as num? ?? 0).toDouble(),
      );

      Navigator.pop(context, {
        'ref_code': _refCode,
        'status': _stockStatus,
        'total_quantity': totalQuantity,
        'total_amount': totalAmount,
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

  void _saveItem() {
    if (_formKey.currentState?.validate() ?? false) {
      final isEditing = _editingIndex != null && _editingIndex! < _items.length;
      final existingId = isEditing
          ? _items[_editingIndex!]['id'] as int?
          : null;

      final quantity =
          double.tryParse(_itemControllers['quantite']?.text.trim() ?? '0') ??
          0.0;
      final unitCost =
          double.tryParse(
            _itemControllers['prix_u']?.text.replaceAll(',', '.') ?? '0',
          ) ??
          0.0;
      final totalAmount = quantity * unitCost;

      final dateText = _itemControllers['date']?.text ?? '';
      final formattedDate = dateText.isNotEmpty
          ? dateText.split(' ').first
          : '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

      final newItem = <String, dynamic>{
        'id': existingId ?? _getLocalNextItemId(),
        'date': formattedDate,
        'n_facture': _itemControllers['n_facture']?.text.trim() ?? '',
        'fournisseur': _itemControllers['fournisseur']?.text.trim() ?? '',
        'ref_code': _itemControllers['ref_code']?.text.trim() ?? '',
        'material_name': _itemControllers['material_name']?.text.trim() ?? '',
        'quantite': quantity,
        'prix_u': unitCost,
        'unite': _itemControllers['unite']?.text.trim() ?? 'KG',
        'total_amount': totalAmount,
        'categorie':
            _itemControllers['categorie']?.text.trim() ?? 'Matières premières',
        'source_ref': _itemControllers['source_ref']?.text.trim() ?? '',
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
        _currentItemStatus = 'Disponible';
        _date = newItem['date']?.toString() ?? _date;
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
      _currentItemStatus = 'Disponible';
    });
  }

  Future<void> _selectDateTime(String key) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _parseDateTime(_itemControllers[key]?.text),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted) return;

    if (pickedDate != null) {
      final formattedDate =
          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
      setState(() {
        _itemControllers[key]?.text = formattedDate;
      });
    }
  }

  DateTime _parseDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return DateTime.now();
    }
    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      return DateTime.now();
    }
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
            Icons.inventory_2_outlined,
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
          _buildHeaderCell('Date', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('N° Facture', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Fournisseur', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Réf Code', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Produit', flex: 2),
          _verticalDivider(height: 28),
          _buildHeaderCell('Quantité', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Prix U.', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Unité', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Montant', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Catégorie', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Source', flex: 1),
          _verticalDivider(height: 28),
          // _buildHeaderCell('Actions', flex: 1),
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
              _buildDataCell(_formatDate(item['date']), flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['n_facture']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['fournisseur']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['ref_code']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['material_name']?.toString() ?? '', flex: 2),
              _verticalDivider(height: 28),
              _buildDataCell(
                _formatNumber((item['quantite'] as num?)?.toDouble() ?? 0),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _formatNumber((item['prix_u'] as num?)?.toDouble() ?? 0),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(item['unite']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(
                _formatNumber((item['total_amount'] as num?)?.toDouble() ?? 0),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(item['categorie']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['source_ref']?.toString() ?? '', flex: 1),
              // const SizedBox(width: 20),
              // SizedBox(
              //   width: 60,
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.end,
              //     children: [
              //       _buildActionIconButton(
              //         icon: Icons.edit,
              //         onPressed: () => _editItem(index),
              //         color: const Color(0xFF3B82F6),
              //       ),
              //       _buildActionIconButton(
              //         icon: Icons.delete_outline,
              //         onPressed: () => _deleteItem(index),
              //         color: Colors.red.shade400,
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(width: 20),
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
            _buildDateTimePickerField('date', 'Date', flex: 1),
            _verticalDivider(height: 28),
            _buildEditField('n_facture', 'N° Facture', flex: 1),
            _verticalDivider(height: 28),
            _buildEditField('fournisseur', 'Fournisseur', flex: 1),
            _verticalDivider(height: 28),
            _buildEditField('ref_code', 'Réf Code', flex: 1),
            _verticalDivider(height: 28),
            _buildEditField('material_name', 'Produit', flex: 2),
            _verticalDivider(height: 28),
            _buildEditField(
              'quantite',
              'Quantité',
              flex: 1,
              isNumber: true,
              isDecimal: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'prix_u',
              'Prix U.',
              flex: 1,
              isNumber: true,
              isDecimal: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField('unite', 'Unité', flex: 1),
            _verticalDivider(height: 28),
            _buildCalculatedAmountField(flex: 1),
            _verticalDivider(height: 28),
            _buildEditField('categorie', 'Catégorie', flex: 1),
            _verticalDivider(height: 28),
            _buildEditField('source_ref', 'Source', flex: 1),
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

  Widget _buildDateTimePickerField(String key, String hint, {int flex = 1}) {
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
            readOnly: true,
            onTap: () => _selectDateTime(key),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
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
              suffixIcon: const Icon(Icons.event, color: Colors.blueAccent),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 5,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ),
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

  Widget _buildCalculatedAmountField({int flex = 1}) {
    // حساب المبلغ تلقائياً
    final quantity =
        double.tryParse(_itemControllers['quantite']?.text.trim() ?? '0') ??
        0.0;
    final unitCost =
        double.tryParse(
          _itemControllers['prix_u']?.text.replaceAll(',', '.') ?? '0',
        ) ??
        0.0;
    final calculatedAmount = quantity * unitCost;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calculate, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatNumber(calculatedAmount),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
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

  Widget _buildStockStatusDropdown() {
    const statuses = ['Disponible', 'Faible', 'Épuisé'];

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Changer le statut du stock'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: statuses.map((status) {
                // ignore: deprecated_member_use
                return RadioListTile<String>(
                  title: Text(status),
                  value: status,
                  // ignore: deprecated_member_use
                  groupValue: _stockStatus,
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _stockStatus = value;
                      });
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _statusColor(_stockStatus).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _statusColor(_stockStatus).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _statusColor(_stockStatus).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color: _statusColor(_stockStatus),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statut Stock',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _statusColor(_stockStatus).withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _stockStatus,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(_stockStatus),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: _statusColor(_stockStatus)),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disponible':
        return const Color(0xFF16A34A);
      case 'faible':
        return const Color(0xFFF59E0B);
      case 'épuisé':
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
