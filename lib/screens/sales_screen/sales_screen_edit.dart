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
  bool _isSaving = false;
  late TabController _tabController;
  int? _editingIndex;
  bool get _hasSelection => _selectedIndices.isNotEmpty;

  final Map<String, TextEditingController> _editControllers = {};

  List<Map<String, dynamic>> _articles = [];

  final List<Map<String, dynamic>> colors = [
    {'Couleur': 'Gris'},
    {'Couleur': 'Noir'},
    {'Couleur': 'Blanc'},
    {'Couleur': 'Bleu'},
    {'Couleur': 'Rouge'},
  ];

  final double peintureVar = 3;
  final double gazVar = 7;
  final double belletVar = 0.14;
  final double dechetVar = 0.84;
  // final double peintureVar = 3;
  // final double gazVar = 7;
  // final double belletVar = 0.18;
  // final double dechetVar = 0.94;

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    return formatter.format(number);
  }

  void _calculateAndUpdateFields() {
    final poids =
        double.tryParse(
          _editControllers['Poids']?.text.replaceAll(',', '.') ?? '0',
        ) ??
        0.0;
    final quantite =
        int.tryParse(
          _editControllers['Quantité']?.text.replaceAll(' ', '') ?? '0',
        ) ??
        0;

    final poidsConsomme = poids * quantite;
    final peinture = poidsConsomme * peintureVar;
    final gaz = poidsConsomme * gazVar;
    final bellet = poidsConsomme / (1 - belletVar);
    final dechet = bellet - poidsConsomme;
    final dechetInitial = bellet / dechetVar;

    _editControllers['Poids consommé']?.text = _formatNumber(poidsConsomme);
    _editControllers['Peinture']?.text = _formatNumber(peinture);
    _editControllers['Gaz']?.text = _formatNumber(gaz);
    _editControllers['bellet']?.text = _formatNumber(bellet);
    _editControllers['dechet']?.text = _formatNumber(dechet);
    _editControllers['dechet initial']?.text = _formatNumber(dechetInitial);
  }

  double _calculateTotalPoidsConsomme() {
    final items = _commandes.isNotEmpty ? _commandes[0]['items'] as List : [];
    double total = 0;
    for (var item in items) {
      total += (item['Poids consommé'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _calculateTotalPeinture() {
    final items = _commandes.isNotEmpty ? _commandes[0]['items'] as List : [];
    double total = 0;
    for (var item in items) {
      total += (item['Peinture'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _calculateTotalGaz() {
    final items = _commandes.isNotEmpty ? _commandes[0]['items'] as List : [];
    double total = 0;
    for (var item in items) {
      total += (item['Gaz'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  double _calculateTotalBellet() {
    final items = _commandes.isNotEmpty ? _commandes[0]['items'] as List : [];
    double total = 0;
    for (var item in items) {
      total += (item['bellet'] as num?)?.toDouble() ?? 0;
    }
    return total;
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
      'Document_Ref': widget.commande['Document_Ref'] ?? 'N/A',
      'Client': widget.commande['Client'] ?? 'N/A',
      'date': widget.commande['date'] ?? 'N/A',
      'items': List<Map<String, dynamic>>.from(widget.items),
    });
  }

  void _initializeControllers() {
    _editControllers['Référence'] = TextEditingController();
    _editControllers['Désignation'] = TextEditingController();
    _editControllers['Poids'] = TextEditingController();
    _editControllers['Quantité'] = TextEditingController();
    _editControllers['Couleur'] = TextEditingController();
    _editControllers['Poids consommé'] = TextEditingController();
    _editControllers['Peinture'] = TextEditingController();
    _editControllers['Gaz'] = TextEditingController();
    _editControllers['bellet'] = TextEditingController();
    _editControllers['dechet'] = TextEditingController();
    _editControllers['dechet initial'] = TextEditingController();
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

  void _loadItemToControllers(Map<String, dynamic> item) {
    _editControllers['Référence']?.text = item['Référence']?.toString() ?? '';
    _editControllers['Désignation']?.text =
        item['Désignation']?.toString() ?? '';
    _editControllers['Poids']?.text = item['Poids']?.toString() ?? '';
    _editControllers['Quantité']?.text = item['Quantité']?.toString() ?? '';
    _editControllers['Couleur']?.text = item['Couleur']?.toString() ?? '';
    _editControllers['Poids consommé']?.text =
        item['Poids consommé']?.toString() ?? '';
    _editControllers['Peinture']?.text = item['Peinture']?.toString() ?? '';
    _editControllers['Gaz']?.text = item['Gaz']?.toString() ?? '';
    _editControllers['bellet']?.text = item['bellet']?.toString() ?? '';
    _editControllers['dechet']?.text = item['dechet']?.toString() ?? '';
    _editControllers['dechet initial']?.text =
        item['dechet initial']?.toString() ?? '';
    _editControllers['date']?.text = item['date']?.toString() ?? '';
    _editControllers['Price']?.text = item['Price']?.toString() ?? '';
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
                      onPressed: () {
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
                      onPressed: _isSaving ? null : _saveCommande,
                      icon: Icons.save_rounded,
                      label: _isSaving ? 'Enregistrement...' : 'Enregistrer',
                      color: const Color(0xFF66BB6A),
                      hoverColor: const Color(0xFF4CAF50),
                      pressedColor: const Color(0xFF81C784),
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
                          icon: Icons.inventory,
                          label: 'Nombre d\'articles',
                          value: itemsCount.toString(),
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.scale,
                          label: 'Poids consommé',
                          value:
                              '${_formatNumber(_calculateTotalPoidsConsomme())} Kg',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.format_paint,
                          label: 'Peinture',
                          value: _formatNumber(_calculateTotalPeinture()),
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.fire_extinguisher,
                          label: 'Gaz',
                          value: _formatNumber(_calculateTotalGaz()),
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.science,
                          label: 'Bellet',
                          value: _formatNumber(_calculateTotalBellet()),
                          color: const Color(0xFF06B6D4),
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
                                  tooltip: 'SÃƒÆ’Ã‚Â©lectionner tout',
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
                                    tooltip: 'Supprimer sÃƒÆ’Ã‚Â©lection',
                                    onTap: _deleteSelected,
                                    icon: Icons.delete_sweep_rounded,
                                    color: const Color(0xFFEF4444),
                                  ),
                                if (_hasSelection)
                                  _buildTooltipButton(
                                    tooltip: 'Effacer sÃƒÆ’Ã‚Â©lection',
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

  Future<void> _saveCommande() async {
    if (_commandes.isEmpty) return;

    final commande = Map<String, dynamic>.from(_commandes.first);
    final items =
        (commande['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    setState(() {
      _isSaving = true;
    });

    try {
      final payload = {...commande, 'items': items};

      final savedOrder = widget.isNewInvoice
          ? await SalesApiService.createOrder(payload)
          : await SalesApiService.updateOrder(payload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isNewInvoice
                ? 'Commande créer avec succès'
                : 'Commande mise à jour avec succès',
          ),
          backgroundColor: Colors.green.shade600,
        ),
      );

      Navigator.pop(context, savedOrder);
    } catch (error, stack) {
      debugPrint('Failed to save order: $error`n$stack');
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

  void _editItem(int index) {
    final items = _commandes[0]['items'] as List;
    setState(() {
      _editingIndex = index;
      _loadItemToControllers(items[index]);
    });
  }

  void _saveItem() {
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

      final poidsConsomme = poids * quantite;
      final peinture = poidsConsomme * peintureVar;
      final gaz = poidsConsomme * gazVar;
      final bellet = poidsConsomme / (1 - belletVar);
      final dechet = bellet - poidsConsomme;
      final dechetInitial = bellet / dechetVar;

      final newItem = {
        'Référence': _editControllers['Référence']?.text ?? '',
        'Désignation': _editControllers['Désignation']?.text ?? '',
        'Poids': double.parse(poids.toStringAsFixed(2)),
        'Quantité': quantite,
        'Couleur': _editControllers['Couleur']?.text ?? '',
        'Poids consommé': double.parse(poidsConsomme.toStringAsFixed(2)),
        'Peinture': double.parse(peinture.toStringAsFixed(2)),
        'Gaz': double.parse(gaz.toStringAsFixed(2)),
        'bellet': double.parse(bellet.toStringAsFixed(2)),
        'dechet': double.parse(dechet.toStringAsFixed(2)),
        'dechet initial': double.parse(dechetInitial.toStringAsFixed(2)),
        'Price': _editControllers['Price'] != null
            ? double.tryParse(
                    _editControllers['Price']?.text.replaceAll(',', '.') ?? '0',
                  ) ??
                  0.0
            : 0.0,
        'date':
            _editControllers['date']?.text ??
            DateTime.now().toString().split(' ')[0],
      };

      setState(() {
        if (_editingIndex != null && _editingIndex! < items.length) {
          items[_editingIndex!] = newItem;
        } else {
          items.add(newItem);
        }
        _editingIndex = null;
        _clearControllers();
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
                final items = _commandes[0]['items'] as List;
                items.removeAt(index);
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
          _buildHeaderCell('Poids consommé', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Peinture', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Gaz', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('Bellet', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('dechet', flex: 1),
          _verticalDivider(height: 28),
          _buildHeaderCell('dechet initial', flex: 1),
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
              _buildDataCell(item['Référence']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['Désignation']?.toString() ?? '', flex: 2),
              _verticalDivider(height: 28),
              _buildDataCell('${item['Poids']?.toString() ?? '0'} Kg', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['Quantité']?.toString() ?? '0', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['Couleur']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(
                '${item['Poids consommé']?.toString() ?? '0'} Kg',
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(item['Peinture']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['Gaz']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['bellet']?.toString() ?? '', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(item['dechet']?.toString() ?? '0', flex: 1),
              _verticalDivider(height: 28),
              _buildDataCell(
                item['dechet initial']?.toString() ?? '0',
                flex: 1,
              ),
              _verticalDivider(height: 28),
              _buildDataCell(item['date']?.toString() ?? '', flex: 1),
              const SizedBox(width: 45),
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

            _buildEditFieldOrDropdown(
              'Référence',
              'Référence',
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
                  selectedValue:
                      _articles
                          .firstWhere(
                            (a) =>
                                a['Désignation'].toString() ==
                                _editControllers['Désignation']?.text,
                            orElse: () => {},
                          )
                          .isEmpty
                      ? null
                      : _articles.firstWhere(
                          (a) =>
                              a['Désignation'].toString() ==
                              _editControllers['Désignation']?.text,
                        ),
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
                        _calculateAndUpdateFields();
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
                setState(() {
                  _calculateAndUpdateFields();
                });
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
                  selectedValue:
                      colors
                          .firstWhere(
                            (c) =>
                                c['Couleur'].toString() ==
                                _editControllers['Couleur']?.text,
                            orElse: () => {},
                          )
                          .isEmpty
                      ? null
                      : colors.firstWhere(
                          (c) =>
                              c['Couleur'].toString() ==
                              _editControllers['Couleur']?.text,
                        ),
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
              'Poids consommé',
              'Poids consommé',
              flex: 1,
              isNumber: true,
              isDecimal: true,
              isReadOnly: true,
            ),
            _verticalDivider(height: 28),
            _buildEditFieldOrDropdown(
              'Peinture',
              'Peinture',
              flex: 1,
              isNumber: true,
              isDecimal: true,
              isReadOnly: true,
            ),
            _verticalDivider(height: 28),
            _buildEditFieldOrDropdown(
              'Gaz',
              'Gaz',
              flex: 1,
              isNumber: true,
              isDecimal: true,
              isReadOnly: true,
            ),
            _verticalDivider(height: 28),
            _buildEditFieldOrDropdown(
              'bellet',
              'Bellet',
              flex: 1,
              isNumber: true,
              isDecimal: true,
              isReadOnly: true,
            ),
            _verticalDivider(height: 28),
            _buildEditFieldOrDropdown(
              'dechet',
              'dechet',
              flex: 1,
              isNumber: true,
              isDecimal: true,
              isReadOnly: true,
            ),
            _verticalDivider(height: 28),
            _buildEditFieldOrDropdown(
              'dechet initial',
              'dechet initial',
              flex: 1,
              isNumber: true,
              isDecimal: true,
              isReadOnly: true,
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

  Widget _buildDataCell(String text, {int flex = 1}) {
    String displayText = text;
    final number = double.tryParse(
      text.replaceAll(' Kg', '').replaceAll(',', '.'),
    );
    if (number != null) {
      displayText = _formatNumber(number);
      if (text.contains('Kg')) {
        displayText += ' Kg';
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
