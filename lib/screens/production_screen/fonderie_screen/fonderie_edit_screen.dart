import '../../../core/imports.dart';
import 'api_services.dart';

class FonderieEditScreen extends StatefulWidget {
  final Map<String, dynamic>? production;
  // Dernière référence existante pour calculer la suivante
  final String? lastRefFonderie;

  const FonderieEditScreen({super.key, this.production, this.lastRefFonderie});

  @override
  State<FonderieEditScreen> createState() => _FonderieEditScreenState();
}

class _FonderieEditScreenState extends State<FonderieEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _items = [];
  final List<int> _selectedIndices = [];
  final FonderieApiService _fonderieApiService = FonderieApiService();
  List<Map<String, dynamic>> _articles = [];
  Map<String, dynamic>? _selectedArticle;
  bool _isSaving = false;
  int? _editingIndex;
  String _currentItemStatus = 'in_progress';

  final Map<String, TextEditingController> _itemControllers = {};
  final Map<String, TextEditingController> _costsControllers = {};
  late final TextEditingController _refArticleController;
  late final TextEditingController _articleNameController;

  // Controllers pour l'en-tête
  String _refFonderie = '';
  String _date = '';
  String _time = '';
  String _refArticle = '';
  String _articleName = '';
  double _cuFondrie = 0.0; // Cost from API

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeData();
    _fetchArticles();
    _loadCosts();
  }

  void _initializeData() {
    final now = DateTime.now();

    final formattedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    _items.clear();

    if (widget.production != null) {
      // Editing existing production - use its ref_fondrie
      final production = Map<String, dynamic>.from(widget.production!);
      _refFonderie = production['ref_fondrie']?.toString() ?? '';
      _refArticle = production['ref_article']?.toString() ?? '';
      _articleName = production['articleName']?.toString() ?? '';

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
      // New production - use the pre-calculated ref from fonderie_screen
      // lastRefFonderie is already the NEXT ref to use (from API or fallback)
      _refFonderie = widget.lastRefFonderie ?? _generateDefaultRef(now);
      _refArticle = '';
      _articleName = '';
      _date = formattedDate;
      _time = formattedTime;
    }
  }

  /// Generate default ref when no lastRefFonderie is provided
  /// Format: FO-YY-MM-00001
  String _generateDefaultRef(DateTime now) {
    final yy = now.year.toString().substring(2);
    final mm = now.month.toString().padLeft(2, '0');
    return 'FO-$yy-$mm-00001';
  }

  void _initializeControllers() {
    _itemControllers['ref_article'] = TextEditingController();
    _itemControllers['articleName'] = TextEditingController();
    _itemControllers['quantity'] = TextEditingController();
    _itemControllers['dechet_fondrie'] = TextEditingController();
    _itemControllers['billete'] = TextEditingController();
    _itemControllers['ref_dechet'] = TextEditingController();
    _itemControllers['cout'] = TextEditingController();
    _refArticleController = TextEditingController(text: _refArticle);
    _articleNameController = TextEditingController(text: _articleName);

    // Add listener to quantity field to auto-calculate dechet_fondrie and billete
    _itemControllers['quantity']?.addListener(_updateCalculatedFields);
  }

  void _updateCalculatedFields() {
    final quantityText = _itemControllers['quantity']?.text.trim() ?? '';
    final quantity = double.tryParse(quantityText) ?? 0.0;

    // Calculate dechet_fondrie = 14% of quantity
    final dechetFondrie = quantity * 0.14;

    // Calculate billete = quantity - 14% (86% of quantity)
    final billete = quantity - (quantity * 0.14);

    // Update the controllers
    _itemControllers['dechet_fondrie']?.text = dechetFondrie.toStringAsFixed(2);
    _itemControllers['billete']?.text = billete.toStringAsFixed(2);
  }

  void _clearControllers() {
    _itemControllers.forEach((key, controller) {
      controller.clear();
    });
    // Reset selected article
    setState(() {
      _selectedArticle = null;
    });
  }

  void _loadItemToControllers(Map<String, dynamic> item) {
    _itemControllers['ref_article']?.text =
        item['ref_article']?.toString() ?? '';
    _itemControllers['articleName']?.text =
        item['articleName']?.toString() ?? '';
    _itemControllers['quantity']?.text = item['quantity']?.toString() ?? '';
    _itemControllers['dechet_fondrie']?.text =
        item['dechet_fondrie']?.toString() ?? '';
    _itemControllers['billete']?.text = item['billete']?.toString() ?? '';
    _itemControllers['ref_dechet']?.text = item['ref_dechet']?.toString() ?? '';
    _itemControllers['cout']?.text = item['cout']?.toString() ?? '';
  }

  Future<void> _fetchArticles() async {
    try {
      final fetchedArticles = await _fonderieApiService.getAllArticlesStock();
      if (!mounted) return;
      setState(() {
        _articles = fetchedArticles;
      });
    } catch (e) {
      if (!mounted) return;
      // Error fetching articles - silent fail
    }
  }

  Future<void> _loadCosts() async {
    if (!mounted) return;

    try {
      final apiService = FonderieApiService();
      final response = await apiService.getCosts();

      if (!mounted) return;

      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'];
        if (mounted) {
          setState(() {
            final fondrie = data['CU_FONDRIE']?.toString() ?? '0';
            _cuFondrie = double.tryParse(fondrie) ?? 0.0;
          });
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _updateRefDechet(String refArticle) {
    String refDechetValue = '';

    // إذا ref_article تبدأ بـ DE → تفريغ ref_dechet (لإجبار المستخدم على اختيار BI)
    if (refArticle.startsWith('DE')) {
      refDechetValue = '';
    } else if (refArticle == 'BI002') {
      // BI002 → DE001
      refDechetValue = 'DE001';
    }
    // أي ref_article أخرى (غير DE وغير BI002) → فارغ

    _itemControllers['ref_dechet']?.text = refDechetValue;
  }

  double _calculateTotalDechet() {
    double total = 0;
    for (var item in _items) {
      total += (item['dechet_fondrie'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _calculateTotalBillete() {
    double total = 0;
    for (var item in _items) {
      total += (item['billete'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _calculateTotalCout() {
    double total = 0;
    for (var item in _items) {
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
      final cout = (item['cout'] as num?)?.toDouble() ?? 0;
      total += quantity * cout;
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
    _costsControllers.forEach((key, controller) {
      controller.dispose();
    });
    _refArticleController.dispose();
    _articleNameController.dispose();
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
                                  Icons.receipt_long_rounded,
                                  color: Color(0xFF1E3A8A),
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.production == null
                                      ? 'Nouvelle Production Fonderie'
                                      : 'Modifier Production Fonderie',
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
                                  'Référence: $_refFonderie',
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
                        final hasCompletedItems = _items.any(
                          (item) => item['status'] == 'completed',
                        );
                        if (hasCompletedItems) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Il n'est pas possible de supprimer les éléments complets.",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
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
                          icon: Icons.delete_outline,
                          label: 'Déchet',
                          value: _formatNumber(_calculateTotalDechet()),
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.view_module,
                          label: 'Billet',
                          value: _formatNumber(_calculateTotalBillete()),
                          color: const Color(0xFF10B981),
                        ),
                      ),

                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.attach_money,
                          label: 'Coût Total',
                          value: '${_formatNumber(_calculateTotalCout())} DH',
                          color: const Color(0xFF8B5CF6),
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
    // Check if we have items
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins une opération avant de sauvegarder.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get ref_article and articleName from the first item
    final firstItem = _items.first;
    final refArticle = firstItem['ref_article']?.toString().trim() ?? '';
    final articleName = firstItem['articleName']?.toString().trim() ?? '';

    if (refArticle.isEmpty || articleName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner la référence et la désignation.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;

      // If it was already created via toggle, we just update it now
      if (_isLocallyCreated) {
        // Prepare items: keep IDs for existing items, remove IDs for new items
        final itemsToSend = _items.map((item) {
          final itemCopy = Map<String, dynamic>.from(item);
          // Only keep ID if it's a real database ID (positive integer)
          // Local temporary IDs should be removed
          final id = itemCopy['id'];
          if (id == null || (id is int && id <= 0)) {
            itemCopy.remove('id');
          }
          return itemCopy;
        }).toList();

        final fondrieData = {'ref_fondrie': _refFonderie, 'items': itemsToSend};
        await _fonderieApiService.updateFondrie(fondrieData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Production mise à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to signal reload
        return;
      }

      // Standard flow (not locally created yet)
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
        (prev, item) => prev + (item['quantity'] as int? ?? 0),
      );
      final totalCout = normalizedItems.fold<double>(
        0,
        (prev, item) => prev + (item['cout'] as num? ?? 0).toDouble(),
      );

      Navigator.pop(context, {
        'ref_fondrie': _refFonderie,
        'ref_article': refArticle,
        'articleName': articleName,
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
    if (_items.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un seul élément peut être ajouté'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _editingIndex = _items.length;
      _clearControllers();
      _itemControllers['date']?.text = DateTime.now().toString().split(' ')[0];
      _itemControllers['ref_article']?.text = _refArticleController.text;
      _itemControllers['articleName']?.text = _articleNameController.text;
      _currentItemStatus = 'in_progress';
      // Set cout from API value
      _itemControllers['cout']?.text = _cuFondrie == 0
          ? ''
          : _cuFondrie.toString();
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
      _currentItemStatus = item['status']?.toString() ?? 'in_progress';
      // Set cout from API value
      _itemControllers['cout']?.text = _cuFondrie == 0
          ? ''
          : _cuFondrie.toString();
    });
  }

  void _saveItem() {
    if (_formKey.currentState?.validate() ?? false) {
      // التحقق من أن ref_dechet غير فارغ
      final refDechet = _itemControllers['ref_dechet']?.text.trim() ?? '';
      if (refDechet.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'يجب اختيار مقال يبدأ بـ BI للحصول على رقم مرجع الديشي',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final isEditing = _editingIndex != null && _editingIndex! < _items.length;
      final existingId = isEditing
          ? _items[_editingIndex!]['id'] as int?
          : null;

      final newItem = <String, dynamic>{
        'id': existingId ?? _getLocalNextItemId(),
        'ref_article': _itemControllers['ref_article']?.text.trim() ?? '',
        'articleName': _itemControllers['articleName']?.text.trim() ?? '',
        'quantity':
            int.tryParse(_itemControllers['quantity']?.text.trim() ?? '0') ?? 0,
        'dechet_fondrie':
            double.tryParse(
              _itemControllers['dechet_fondrie']?.text.replaceAll(',', '.') ??
                  '0',
            ) ??
            0.0,
        'billete':
            double.tryParse(
              _itemControllers['billete']?.text.replaceAll(',', '.') ?? '0',
            ) ??
            0.0,
        'ref_dechet': _itemControllers['ref_dechet']?.text.trim() ?? '',
        'cout': _cuFondrie,
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

  bool _isLocallyCreated = false;

  Future<bool> _createProductionInitial(Map<String, dynamic> item) async {
    // Validate basic requirements before creating
    final refArticle = item['ref_article']?.toString().trim() ?? '';
    final articleName = item['articleName']?.toString().trim() ?? '';

    if (refArticle.isEmpty || articleName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez renseigner la référence et la désignation avant de changer le statut.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare data for creation
      // Use current status (likely in_progress)
      final itemForCreation = Map<String, dynamic>.from(item);

      // Ensure ID is set (though backend might ignore or use it)
      if (itemForCreation['id'] == null) {
        itemForCreation['id'] = _getLocalNextItemId();
      }

      final fondrieData = {
        'ref_fondrie': _refFonderie,
        'items': [itemForCreation],
      };

      // Call create API
      final result = await _fonderieApiService.createFondrie(fondrieData);

      if (!mounted) return false;

      // Update local state with result
      setState(() {
        _isLocallyCreated = true;
        // Update items with returned data to get real IDs
        if (result['items'] != null) {
          final returnedItems = (result['items'] as List)
              .cast<Map<String, dynamic>>();
          if (returnedItems.isNotEmpty) {
            // Assuming single item creation, we update our single item
            if (_items.length == 1) {
              _items[0] = returnedItems.first;
            } else {
              final returnedItem = returnedItems.first;
              final index = _items.indexOf(item);
              if (index != -1) {
                _items[index] = returnedItem;
              }
            }
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Production créée. Mise à jour du statut...'),
          backgroundColor: Colors.green,
        ),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _updateItemStatus(Map<String, dynamic> item, int index) async {
    final currentStatus = item['status'] ?? 'in_progress';
    final newStatus = currentStatus == 'completed'
        ? 'in_progress'
        : 'completed';

    // If new production, create it first
    if (widget.production == null && !_isLocallyCreated) {
      final created = await _createProductionInitial(item);
      if (!created) return;

      // Re-fetch item to get the new ID and data from the list
      // The 'item' variable still holds the old map reference
      if (index < _items.length) {
        item = _items[index];
      }
    }

    final itemId = item['id']; // Now this should have the ID from DB

    // Existing production (or locally created). Try to update via API.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mise à jour du statut...'),
          duration: Duration(seconds: 1),
        ),
      );

      try {
        await _fonderieApiService.updateFoundryItemStatus(
          refFondrie: _refFonderie,
          itemId: itemId is int ? itemId : int.tryParse(itemId.toString()) ?? 0,
          oldStatus: currentStatus,
          newStatus: newStatus,
          itemData: item,
        );

        if (!mounted) return;

        setState(() {
          item['status'] = newStatus;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'completed'
                  ? 'Statut mis à jour: Terminé (Stock mis à jour)'
                  : 'Statut mis à jour: En cours (Stock rétabli)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        // If error is "Inventory is empty", do not update status locally
        if (e.toString().contains('المخزن فارغ')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('المخزن فارغ: لا يمكن إتمام العملية'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          item['status'] = newStatus;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Statut changé localement (Non synchronisé: ${e.toString().split(':').last.trim()})',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _clearControllers();
      _currentItemStatus = 'in_progress';
    });
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
          _buildHeaderCell('Référence', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Désignation', flex: 2),
          _verticalDivider(height: 28),
          _buildHeaderCell('Quantité', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Déchet', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Billet', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Réf Déchet', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Coût (DH)', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Actions', flex: 2),
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
              _buildDataCell(item['ref_article']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['articleName']?.toString() ?? '', flex: 2),
              _verticalDivider(height: 28),
              _buildDataCell(item['quantity']?.toString() ?? '0', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(
                _formatNumber(
                  (item['dechet_fondrie'] as num?)?.toDouble() ?? 0,
                ),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                _formatNumber((item['billete'] as num?)?.toDouble() ?? 0),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(item['ref_dechet']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(
                _formatNumber((item['cout'] as num?)?.toDouble() ?? 0),
                flex: 1,
              ),
              _verticalDivider(height: 28),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status chip with toggle
                      Expanded(
                        child: InkWell(
                          onTap: () => _updateItemStatus(item, index),
                          borderRadius: BorderRadius.circular(16),
                          child: _buildStatusChip(
                            (item['status'] ?? 'in_progress').toString(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Action buttons
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildEnhancedActionButton(
                          icon: Icons.edit_rounded,
                          onPressed: (item['status'] == 'completed')
                              ? null
                              : () => _editItem(index),
                          color: const Color(0xFF3B82F6),
                          tooltip: 'Modifier',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditRow(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF60A5FA).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6), width: 2),
      ),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            const SizedBox(width: 8),
            _buildEditField(
              'ref_article',
              'Référence',
              flex: 1,
              isReadOnly: true,
            ),
            _verticalDivider(height: 28),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: SearchableDropdownT<Map<String, dynamic>>(
                  items: _articles,
                  displayText: (article) => article['material_name'] ?? '',
                  selectedValue: _selectedArticle,
                  onChanged: (article) {
                    setState(() {
                      _selectedArticle = article;
                      if (article != null) {
                        _itemControllers['articleName']?.text =
                            article['material_name'] ?? '';
                        // Auto-populate ref_article
                        final refArticle = article['ref_code'] ?? '';
                        _itemControllers['ref_article']?.text = refArticle;

                        // Auto-populate ref_dechet based on ref_article logic
                        _updateRefDechet(refArticle);
                      } else {
                        _itemControllers['articleName']?.clear();
                        _itemControllers['ref_article']?.clear();
                        _itemControllers['ref_dechet']?.clear();
                      }
                    });
                  },
                  hintText: 'Sélectionner un article',
                  onPrefixIconTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ArticlesStockCrudScreen(),
                      ),
                    );
                  },
                  searchHint: 'Recherche...',
                  noResultsText: 'Aucun résultat',
                  loadingText: 'Chargement...',
                  isLoading: _articles.isEmpty,
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  primaryColor: Colors.blue,
                  enabled: true,
                ),
              ),
            ),
            _verticalDivider(height: 28),
            _buildEditField('quantity', 'Quantité', flex: 1, isNumber: true),
            _verticalDivider(height: 28),
            _buildEditField(
              'dechet_fondrie',
              'Déchet',
              flex: 1,
              isNumber: true,
              isDecimal: true,
              isReadOnly: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'billete',
              'Billet',
              flex: 1,
              isNumber: true,
              isDecimal: true,
              isReadOnly: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'ref_dechet',
              'Réf Déchet *',
              flex: 1,
              isNumber: false,
              isDecimal: false,
              isReadOnly: true,
            ),
            _verticalDivider(height: 28),
            _buildEditField(
              'cout',
              'Coût',
              flex: 1,
              isNumber: true,
              isDecimal: true,
              isReadOnly: true,
            ),
            _verticalDivider(height: 28),
            _buildStatusDropdown(),
            const SizedBox(width: 3),
            SizedBox(
              width: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionIconButton(
                    icon: Icons.save,
                    onPressed: () {
                      // Check if article is selected first
                      if (_selectedArticle == null ||
                          _itemControllers['articleName']?.text.isEmpty ==
                              true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez sélectionner un article'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      _saveItem();
                    },
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
            const SizedBox(width: 8),
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
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
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

  Widget _buildEnhancedActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
    required String tooltip,
  }) {
    final isEnabled = onPressed != null;
    final effectiveColor = isEnabled ? color : Colors.grey;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: effectiveColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 16, color: effectiveColor),
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

  Widget _buildStatusDropdown() {
    const statuses = [
      {'value': 'in_progress', 'label': 'En cours'},
      {'value': 'completed', 'label': 'Terminé'},
    ];

    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Container(
          height: 48,
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
                vertical: 8,
              ),
              filled: true,
              fillColor: Colors.white,
              hintText: 'Statut',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
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
                    value: status['value'],
                    child: Text(
                      status['label']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _statusColor(status['value']!),
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
    final statusInfo = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusInfo['color'].withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusInfo['color'].withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo['icon'], size: 14, color: statusInfo['color']),
          const SizedBox(width: 6),
          Text(
            statusInfo['label'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: statusInfo['color'],
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return {
          'label': 'En cours',
          'color': const Color(0xFFF59E0B),
          'icon': Icons.autorenew_rounded,
        };
      case 'completed':
        return {
          'label': 'Terminé',
          'color': const Color(0xFF16A34A),
          'icon': Icons.check_circle_rounded,
        };
      default:
        return {
          'label': 'En cours',
          'color': const Color(0xFFF59E0B),
          'icon': Icons.autorenew_rounded,
        };
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFFF59E0B);
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
