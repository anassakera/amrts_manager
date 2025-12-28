import 'package:amrts_manager/widgets/search_able_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'api_services.dart';

class SalesScreenEdit extends StatefulWidget {
  final List<dynamic> items;
  final Map<String, dynamic> commande;
  final bool isNewInvoice;

  const SalesScreenEdit({
    super.key,
    required this.items,
    required this.commande,
    this.isNewInvoice = false,
  });

  @override
  State<SalesScreenEdit> createState() => _SalesScreenEditState();
}

class _SalesScreenEditState extends State<SalesScreenEdit>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _commandes = [];
  final List<int> _selectedIndices = [];
  final bool _isSaving = false;
  bool _isSavingItem = false; // For item-level saving indicator
  bool _orderSavedToBackend = false; // Track if order has been saved to backend
  int? _savedOrderId; // Store the order ID after first save
  late TabController _tabController;
  int? _editingIndex;
  bool get _hasSelection => _selectedIndices.isNotEmpty;
  bool get _hasItems =>
      _commandes.isNotEmpty && (_commandes[0]['items'] as List).isNotEmpty;

  /// Check if quantity is valid for saving (not empty and > 0)
  bool get _canSaveItem {
    final quantityText =
        _editControllers['Quantité']?.text.replaceAll(' ', '') ?? '';
    final quantity = int.tryParse(quantityText) ?? 0;
    return quantity > 0 && !_isSavingItem;
  }

  final Map<String, TextEditingController> _editControllers = {};

  List<Map<String, dynamic>> _articles = [];

  final List<Map<String, dynamic>> colors = [
    {'Couleur': 'Gris'},
    {'Couleur': 'Noir'},
    {'Couleur': 'Blanc'},
    {'Couleur': 'Bleu'},
    {'Couleur': 'Rouge'},
  ];

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    return formatter.format(number);
  }

  double _calculateTotalPrice() {
    final items = _commandes.isNotEmpty ? _commandes[0]['items'] as List : [];
    double total = 0;
    for (var item in items) {
      final price = (item['Price'] as num?)?.toDouble() ?? 0;
      final quantite = (item['Quantité'] as num?)?.toInt() ?? 0;
      total += price * quantite;
    }
    return total;
  }

  /// Calculate total for current item being edited
  double _calculateItemTotal() {
    final priceText =
        _editControllers['Price']?.text
            .replaceAll(',', '.')
            .replaceAll(' ', '') ??
        '0';
    final quantityText =
        _editControllers['Quantité']?.text.replaceAll(' ', '') ?? '0';

    final price = double.tryParse(priceText) ?? 0.0;
    final quantity = int.tryParse(quantityText) ?? 0;

    return price * quantity;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeCommandes();
    _initializeControllers();
    _loadArticles();
  }

  void _initializeCommandes() {
    _commandes.clear();
    _commandes.add({
      'id': widget.commande['id'],
      'Document_Ref': widget.commande['Document_Ref'] ?? 'N/A',
      'doc_type': widget.commande['doc_type'] ?? 'BL',
      'Client': widget.commande['Client'] ?? 'N/A',
      'date': widget.commande['date'] ?? 'N/A',
      'status': widget.commande['status'] ?? 'pending',
      'items': List<Map<String, dynamic>>.from(
        (widget.items).map((item) => Map<String, dynamic>.from(item as Map)),
      ),
    });

    // If this is an existing order (not new), mark it as already saved to backend
    if (!widget.isNewInvoice && widget.commande['id'] != null) {
      _orderSavedToBackend = true;
      _savedOrderId = widget.commande['id'] as int?;
    }
  }

  void _initializeControllers() {
    _editControllers['Référence'] = TextEditingController();
    _editControllers['Désignation'] = TextEditingController();
    _editControllers['Poids'] = TextEditingController();
    _editControllers['Quantité'] = TextEditingController();
    _editControllers['Couleur'] = TextEditingController();
    _editControllers['date'] = TextEditingController();
    _editControllers['Price'] = TextEditingController();
  }

  Future<void> _loadArticles() async {
    try {
      final results = await SalesApiService.fetchArticles();
      if (!mounted) return;
      setState(() {
        _articles = results;
      });
    } catch (error, stack) {
      debugPrint('Failed to load articles: $error');
      debugPrint(stack.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des articles: $error'),
          ),
        );
      }
    }
  }

  void _clearControllers() {
    _editControllers.forEach((key, controller) {
      controller.clear();
    });
  }

  /// Helper method to get selected article without type issues
  Map<String, dynamic>? _getSelectedArticle() {
    final searchText = _editControllers['Désignation']?.text ?? '';
    if (searchText.isEmpty) return null;

    try {
      return _articles.firstWhere(
        (a) => a['Désignation'].toString() == searchText,
      );
    } catch (e) {
      return null;
    }
  }

  /// Helper method to get selected color without type issues
  Map<String, dynamic>? _getSelectedColor() {
    final searchText = _editControllers['Couleur']?.text ?? '';
    if (searchText.isEmpty) return null;

    try {
      return colors.firstWhere((c) => c['Couleur'].toString() == searchText);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _editControllers.forEach((key, controller) {
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
    final currentCommande = _commandes.isNotEmpty ? _commandes[0] : null;
    final itemsCount = currentCommande?['items']?.length ?? 0;

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
                                  widget.isNewInvoice
                                      ? 'Nouveau Bon de Commande'
                                      : 'Bon de Commande',
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
                                  'Référence: ${currentCommande?['Document_Ref'] ?? 'N/A'}',
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
                                  currentCommande?['Client'] ?? 'N/A',
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
                                  currentCommande?['date'] ?? 'N/A',
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
                      onPressed:
                          (_hasItems ||
                              _orderSavedToBackend ||
                              _isSavingItem ||
                              _isSaving ||
                              _editingIndex != null)
                          ? null // Disable when items exist, order is saved, or user is editing
                          : () {
                              Navigator.pop(context);
                            },
                      icon: Icons.cancel_rounded,
                      label: 'Annuler',
                      color: const Color(0xFFE57373),
                      hoverColor: const Color(0xFFEF5350),
                      pressedColor: const Color(0xFFEF9A9A),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      onPressed: (_isSaving || _isSavingItem)
                          ? null
                          : () {
                              // Since order is already saved, just close and return
                              if (_orderSavedToBackend &&
                                  _commandes.isNotEmpty) {
                                Navigator.pop(context, _commandes.first);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                      icon: Icons.check_circle_rounded,
                      label: _isSavingItem ? 'Enregistrement...' : 'Terminer',
                      color: const Color(0xFF66BB6A),
                      hoverColor: const Color(0xFF4CAF50),
                      pressedColor: const Color(0xFF81C784),
                      isLoading: _isSavingItem,
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
                          icon: Icons.inventory,
                          label: 'Nombre d\'articles',
                          value: itemsCount.toString(),
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.attach_money,
                          label: 'Prix Total',
                          value: '${_formatNumber(_calculateTotalPrice())} DH',
                          color: const Color(0xFFEF4444),
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
                                  tooltip: 'Selectionner tout',
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
                                    tooltip: 'Supprimer ',
                                    onTap: _deleteSelected,
                                    icon: Icons.delete_sweep_rounded,
                                    color: const Color(0xFFEF4444),
                                  ),
                                if (_hasSelection)
                                  _buildTooltipButton(
                                    tooltip: 'Effacer',
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

  void _addNewItem() {
    setState(() {
      _editingIndex = (_commandes[0]['items'] as List).length;
      _clearControllers();

      _editControllers['date']?.text = DateTime.now().toString().split(' ')[0];
    });
  }

  void _selectAll() {
    setState(() {
      final items = _commandes[0]['items'] as List;
      _selectedIndices.clear();
      for (int i = 0; i < items.length; i++) {
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
        title: const Text(
          'ÃƒËœÃ‚ÂªÃƒËœÃ‚Â£Ãƒâ„¢Ã†â€™Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¯ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â­ÃƒËœÃ‚Â°Ãƒâ„¢Ã‚Â',
        ),
        content: Text(
          'Ãƒâ„¢Ã¢â‚¬Â¡Ãƒâ„¢Ã¢â‚¬Å¾ ÃƒËœÃ‚ÂªÃƒËœÃ‚Â±Ãƒâ„¢Ã…Â ÃƒËœÃ‚Â¯ ÃƒËœÃ‚Â­ÃƒËœÃ‚Â°Ãƒâ„¢Ã‚Â ${_selectedIndices.length} ÃƒËœÃ‚Â¹Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚ÂµÃƒËœÃ‚Â±ÃƒËœÃ…Â¸',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ÃƒËœÃ‚Â¥Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚ÂºÃƒËœÃ‚Â§ÃƒËœÃ‚Â¡'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final items = _commandes[0]['items'] as List;

                _selectedIndices.sort((a, b) => b.compareTo(a));
                for (var index in _selectedIndices) {
                  items.removeAt(index);
                }
                _selectedIndices.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'ÃƒËœÃ‚ÂªÃƒâ„¢Ã¢â‚¬Â¦ ÃƒËœÃ‚Â­ÃƒËœÃ‚Â°Ãƒâ„¢Ã‚Â ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â¹Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â§ÃƒËœÃ‚ÂµÃƒËœÃ‚Â± ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â§ÃƒËœÃ‚Â­',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'ÃƒËœÃ‚Â­ÃƒËœÃ‚Â°Ãƒâ„¢Ã‚Â',
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

  Future<void> _saveItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      final items = _commandes[0]['items'] as List<Map<String, dynamic>>;

      final poids =
          double.tryParse(
            _editControllers['Poids']?.text
                    .replaceAll(',', '.')
                    .replaceAll(' ', '') ??
                '0',
          ) ??
          0.0;
      final quantite =
          int.tryParse(
            _editControllers['Quantité']?.text.replaceAll(' ', '') ?? '0',
          ) ??
          0;
      final price =
          double.tryParse(
            _editControllers['Price']?.text
                    .replaceAll(',', '.')
                    .replaceAll(' ', '') ??
                '0',
          ) ??
          0.0;

      final productRef = _editControllers['Référence']?.text ?? '';
      final productName = _editControllers['Désignation']?.text ?? '';
      final color = _editControllers['Couleur']?.text ?? '';

      // Get document type
      final docType =
          (_commandes.isNotEmpty ? _commandes[0]['doc_type'] : null) ?? 'BL';

      // Only BL affects inventory - skip stock check for BC and DE
      if (docType == 'BL') {
        // Check stock availability before saving
        try {
          final stockResult = await SalesApiService.checkStockSPF(
            productRef: productRef,
            requiredQty: quantite,
            color: color.isNotEmpty ? color : null,
          );

          debugPrint('Stock check result: $stockResult');

          final foundInSpf = stockResult['found_in_spf'] as bool? ?? false;
          final currentStock = stockResult['current_stock'] ?? 0;
          final calculatedStock = stockResult['calculated_stock'] ?? 0;
          final isAvailable = stockResult['available'] as bool? ?? false;

          // Check if stock is available (either from inventory_spf or calculated from operations)
          if (!isAvailable) {
            if (!mounted) return;

            // If product not found in SPF and no calculated stock
            if (!foundInSpf && calculatedStock <= 0) {
              await _showStockWarningDialog(
                title: 'Produit non trouvé',
                icon: Icons.search_off_rounded,
                iconColor: Colors.orange,
                message:
                    'Le produit "$productName" (Ref: $productRef) n\'existe pas dans le stock SPF.',
                details:
                    'Veuillez d\'abord ajouter ce produit au stock des produits finis.',
              );
              return;
            }

            // Stock insufficient
            await _showStockWarningDialog(
              title: 'Stock insuffisant',
              icon: Icons.inventory_2_outlined,
              iconColor: Colors.red,
              message: 'La quantité demandée dépasse le stock disponible.',
              details:
                  'Produit: $productName\nDisponible: $currentStock unités\nDemandé: $quantite unités',
              showStockInfo: true,
              availableStock: currentStock,
              requiredStock: quantite,
            );
            return;
          }
        } catch (e) {
          debugPrint('Stock check failed: $e');
          // Continue without stock check if API fails
        }
      }

      // Preserve item id if editing existing item
      final existingItem =
          (_editingIndex != null && _editingIndex! < items.length)
          ? items[_editingIndex!]
          : null;

      final newItem = {
        'id': existingItem?['id'],
        'Référence': productRef,
        'Désignation': productName,
        'Poids': double.parse(poids.toStringAsFixed(4)),
        'Quantité': quantite,
        'Couleur': color,
        'Price': price,
        'total_price': quantite * price,
        'date': DateTime.now().toString().split(' ')[0],
      };

      // Add/update item in local list first
      setState(() {
        if (_editingIndex != null && _editingIndex! < items.length) {
          items[_editingIndex!] = newItem;
        } else {
          items.add(newItem);
        }
        _isSavingItem = true;
      });

      // === SAVE TO BACKEND IMMEDIATELY ===
      try {
        final commande = Map<String, dynamic>.from(_commandes.first);
        final currentItems =
            (commande['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final payload = {...commande, 'items': currentItems};

        Map<String, dynamic> savedOrder;

        // Determine if this is a new order or updating existing
        final shouldCreate = widget.isNewInvoice && !_orderSavedToBackend;

        if (shouldCreate) {
          // First save for new order: create order
          savedOrder = await SalesApiService.createOrder(payload);
          _savedOrderId = savedOrder['id'] as int?;
          _orderSavedToBackend = true;

          // Update local commande with saved ID
          setState(() {
            _commandes[0]['id'] = _savedOrderId;
            // Update items with their IDs from the response
            final savedItems =
                savedOrder['items'] as List? ??
                savedOrder['sales_operations'] as List? ??
                [];
            if (savedItems.isNotEmpty) {
              for (int i = 0; i < items.length && i < savedItems.length; i++) {
                items[i]['id'] = savedItems[i]['id'];
              }
            }
          });
        } else {
          // Update existing order (or subsequent saves for new order)
          savedOrder = await SalesApiService.updateOrder(payload);
          _orderSavedToBackend = true;

          // Update items with their IDs from the response
          final savedItems =
              savedOrder['items'] as List? ??
              savedOrder['sales_operations'] as List? ??
              [];
          if (savedItems.isNotEmpty) {
            setState(() {
              for (int i = 0; i < items.length && i < savedItems.length; i++) {
                items[i]['id'] = savedItems[i]['id'];
              }
            });
          }
        }

        setState(() {
          _editingIndex = null;
          _clearControllers();
          _isSavingItem = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article enregistré et stock mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        debugPrint('Failed to save item to backend: $e');

        // Remove the item we just added since save failed
        setState(() {
          if (_editingIndex == null) {
            items.removeLast();
          }
          _isSavingItem = false;
        });

        if (!mounted) return;

        final errorMessage = e.toString();
        if (errorMessage.contains('Stock insuffisant')) {
          final regex = RegExp(
            r"Stock insuffisant pour '(.+)' \((.+)\)\. Disponible: (\d+), Demandé: (\d+)",
          );
          final match = regex.firstMatch(errorMessage);

          if (match != null) {
            final prodName = match.group(1) ?? 'Produit';
            final prodColor = match.group(2) ?? '';
            final available = int.tryParse(match.group(3) ?? '0') ?? 0;
            final required = int.tryParse(match.group(4) ?? '0') ?? 0;

            await _showStockWarningDialog(
              title: 'Stock insuffisant',
              icon: Icons.inventory_2_outlined,
              iconColor: Colors.red,
              message: 'La quantité demandée dépasse le stock disponible.',
              details: 'Produit: $prodName\nCouleur: $prodColor',
              showStockInfo: true,
              availableStock: available,
              requiredStock: required,
            );
          } else {
            await _showStockWarningDialog(
              title: 'Stock insuffisant',
              icon: Icons.inventory_2_outlined,
              iconColor: Colors.red,
              message: 'La quantité demandée dépasse le stock disponible.',
              details: errorMessage.replaceAll('Exception: ', ''),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      }
    }
  }

  /// Show a beautiful stock warning dialog
  Future<void> _showStockWarningDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String message,
    required String details,
    bool showStockInfo = false,
    int availableStock = 0,
    int requiredStock = 0,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, iconColor.withValues(alpha: 0.05)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with animated container
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 40, color: iconColor),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: iconColor.withValues(alpha: 0.9),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: showStockInfo
                      ? Column(
                          children: [
                            _buildStockRow(
                              'Disponible',
                              '$availableStock unités',
                              Colors.green.shade600,
                              Icons.check_circle_outline,
                            ),
                            const SizedBox(height: 8),
                            _buildStockRow(
                              'Demandé',
                              '$requiredStock unités',
                              Colors.red.shade600,
                              Icons.remove_circle_outline,
                            ),
                            const Divider(height: 20),
                            _buildStockRow(
                              'Manquant',
                              '${requiredStock - availableStock} unités',
                              Colors.orange.shade700,
                              Icons.warning_amber_outlined,
                            ),
                          ],
                        )
                      : Text(
                          details,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(height: 24),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: iconColor.withValues(alpha: 0.4),
                    ),
                    child: const Text(
                      'Compris',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockRow(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _clearControllers();
    });
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous supprimer cet article ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (!mounted) return;

              final items =
                  _commandes[0]['items'] as List<Map<String, dynamic>>;
              final itemToDelete = items[index];

              debugPrint('Delete item: index=$index, item=$itemToDelete');
              debugPrint('_orderSavedToBackend=$_orderSavedToBackend');

              // Remove item locally first
              setState(() {
                items.removeAt(index);
              });

              debugPrint('Items after removal: ${items.length} items');

              // If order is saved to backend, update it to sync deletion
              if (_orderSavedToBackend && _commandes.isNotEmpty) {
                try {
                  final commande = Map<String, dynamic>.from(_commandes.first);
                  final currentItems =
                      (commande['items'] as List?)
                          ?.cast<Map<String, dynamic>>() ??
                      [];
                  final payload = {...commande, 'items': currentItems};

                  debugPrint(
                    'Sending delete update with ${currentItems.length} items',
                  );

                  await SalesApiService.updateOrder(payload);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Article supprimé et stock restauré'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  debugPrint('Failed to sync deletion: $e');

                  // Restore item locally if backend update failed
                  if (mounted) {
                    setState(() {
                      items.insert(index, itemToDelete);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la suppression: $e'),
                        backgroundColor: Colors.red.shade400,
                      ),
                    );
                  }
                }
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Article supprimé'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
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
    final items = _commandes.isNotEmpty
        ? (_commandes[0]['items'] as List<dynamic>)
        : [];
    final isAddingNew = _editingIndex == items.length;
    final itemCount = items.length + (isAddingNew ? 1 : 0);

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
                        return _buildEditRow(items.length);
                      } else {
                        final actualIndex = isAddingNew ? index - 1 : index;
                        return _buildTableRow(items[actualIndex], actualIndex);
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
            'Aucun élément', // <-- تم التصحيح والترجمة
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cliquez sur "Ajouter nouveau" pour ajouter un élément', // <-- تم التصحيح والترجمة
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
          _buildHeaderCell('Poids', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Quantité', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Couleur', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Prix U.', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Total', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Date', flex: 1),
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
              _buildDataCell(
                item['Référence']?.toString() ?? '',
                flex: 1,
                isText: true,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                item['Désignation']?.toString() ?? '',
                flex: 2,
                isText: true,
              ),
              _verticalDivider(height: 28),
              _buildDataCell('${item['Poids']?.toString() ?? '0'} Kg', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(
                '${(item['Quantité'] as num?)?.toInt() ?? 0}',
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                item['Couleur']?.toString() ?? '',
                flex: 1,
                isText: true,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                '${_formatNumber((item['Price'] as num?)?.toDouble() ?? 0.0)} DH',
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(
                '${_formatNumber((item['total_price'] as num?)?.toDouble() ?? ((item['Price'] as num?)?.toDouble() ?? 0.0) * ((item['Quantité'] as num?)?.toInt() ?? 0))} DH',
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(item['date']?.toString() ?? '', flex: 1),
              const SizedBox(width: 45),
              SizedBox(
                width: 40,
                child: _buildActionIconButton(
                  icon: Icons.delete_outline,
                  onPressed: () => _deleteItem(index),
                  color: Colors.red.shade400,
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

            _buildEditFieldOrDropdown(
              'Référence',
              'Référence',
              isDecimal: false,
              flex: 1,
              isReadOnly: true,
            ),
            _verticalDivider(height: 28),

            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: SearchableDropdownT<Map<String, dynamic>>(
                  items: _articles,
                  displayText: (item) => item['Désignation'].toString(),
                  selectedValue: _getSelectedArticle(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _editControllers['Désignation']?.text =
                            value['Désignation'].toString();
                        _editControllers['Référence']?.text =
                            value['Référence']?.toString() ?? '';
                        final poids =
                            (value['Poids'] as num?)?.toDouble() ?? 0.0;
                        _editControllers['Poids']?.text = _formatNumber(poids);
                        final price =
                            (value['Price'] as num?)?.toDouble() ?? 0.0;
                        _editControllers['Price']?.text = _formatNumber(price);
                      });
                    }
                  },
                  hintText: 'Désignation',
                  searchHint: 'Rechercher article...',
                  primaryColor: const Color(0xFF3B82F6),
                ),
              ),
            ),
            _verticalDivider(height: 28),

            _buildEditFieldOrDropdown(
              'Poids',
              'Poids',
              flex: 1,
              isNumber: true,
              isDecimal: true,
              isReadOnly: true,
            ),
            _verticalDivider(height: 28),

            _buildEditFieldOrDropdown(
              'Quantité',
              'Quantité',
              flex: 1,
              isNumber: true,
              isDecimal: false,
              onChanged: (value) {
                // Trigger rebuild to update total calculation
                setState(() {});
              },
            ),
            _verticalDivider(height: 28),

            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: SearchableDropdownT<Map<String, dynamic>>(
                  items: colors,
                  displayText: (item) => item['Couleur'].toString(),
                  selectedValue: _getSelectedColor(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _editControllers['Couleur']?.text = value['Couleur']
                            .toString();
                      });
                    }
                  },
                  hintText: 'Couleur',
                  searchHint: 'Rechercher couleur...',
                  primaryColor: const Color(0xFF3B82F6),
                ),
              ),
            ),
            _verticalDivider(height: 28),

            _buildEditFieldOrDropdown(
              'Price',
              'Prix U.',
              flex: 1,
              isNumber: true,
              isDecimal: true,
              isReadOnly: true,
            ),
            _verticalDivider(height: 28),

            // Total (calculated, read-only)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '${_formatNumber(_calculateItemTotal())} DH',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            _verticalDivider(height: 28),

            _buildEditFieldOrDropdown(
              'date',
              'Date',
              flex: 1,
              isReadOnly: true,
            ),
            const SizedBox(width: 30),
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  _buildActionIconButton(
                    icon: Icons.save,
                    onPressed: _canSaveItem
                        ? () {
                            _saveItem();
                          }
                        : null,
                    color: _canSaveItem
                        ? const Color(0xFF1E3A8A)
                        : Colors.grey.shade400,
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
    required Color hoverColor,
    required Color pressedColor,
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
            if (isLoading)
              const SizedBox(width: 8)
            else
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

  Widget _buildDataCell(String text, {int flex = 1, bool isText = false}) {
    String displayText = text;

    // Only format as number if it's not marked as text and looks like a pure number
    if (!isText) {
      // Remove units before parsing
      final cleanText = text
          .replaceAll(' Kg', '')
          .replaceAll(' DH', '')
          .replaceAll(',', '.')
          .trim();

      // Check if it's a pure numeric value (not alphanumeric like REF001)
      final isPureNumber = RegExp(r'^-?[0-9]*\.?[0-9]+$').hasMatch(cleanText);

      if (isPureNumber) {
        final number = double.tryParse(cleanText);
        if (number != null) {
          displayText = _formatNumber(number);
          if (text.contains('Kg')) {
            displayText += ' Kg';
          } else if (text.contains('DH')) {
            displayText += ' DH';
          }
        }
      }
    }

    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Text(
          displayText,
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
    VoidCallback? onPressed,
    required Color color,
  }) {
    return IconButton(
      icon: Icon(icon, size: 16, color: color),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  Widget _buildEditFieldOrDropdown(
    String key,
    String hint, {
    int flex = 1,
    bool isNumber = false,
    bool isDecimal = false,
    bool isDropdown = false,
    bool isReadOnly = false,
    List<String>? dropdownItems,
    Function(String?)? onChanged,
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
          child: isDropdown
              ? DropdownButtonFormField<String>(
                  initialValue: _editControllers[key]?.text.isEmpty ?? true
                      ? null
                      : _editControllers[key]?.text,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 5,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: dropdownItems?.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â·Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¨';
                    }
                    return null;
                  },
                )
              : TextFormField(
                  controller: _editControllers[key],
                  readOnly: isReadOnly,
                  keyboardType: isNumber
                      ? (isDecimal
                            ? const TextInputType.numberWithOptions(
                                decimal: true,
                              )
                            : TextInputType.number)
                      : TextInputType.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: isReadOnly ? Colors.grey.shade600 : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  inputFormatters: isNumber
                      ? [
                          isDecimal
                              ? FilteringTextInputFormatter.allow(
                                  RegExp(r'^[0-9]*\.?[0-9]*'),
                                )
                              : FilteringTextInputFormatter.digitsOnly,
                        ]
                      : [],
                  onChanged: onChanged,
                  validator: (value) {
                    if (!isReadOnly && (value == null || value.isEmpty)) {
                      return 'Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â·Ãƒâ„¢Ã¢â‚¬Å¾Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¨';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
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

  Widget _verticalDivider({double? height}) {
    return Container(
      width: 1,
      height: height ?? double.infinity,
      color: const Color(0xFFE5E7EB),
    );
  }
}
