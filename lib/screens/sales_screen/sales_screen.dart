import 'dart:async';
import 'package:amrts_manager/services/print_sales_documents.dart';
import 'package:amrts_manager/widgets/add_document_dialog.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../core/imports.dart';
import 'api_services.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  final List<Map<String, dynamic>> _commandes = [];
  bool _isLoading = false;
  String? _errorMessage;
  final int _currentPage = 1;
  final int _pageSize = 20;
  Timer? _searchDebounce;
  Map<String, dynamic>? _remoteStats;
  final bool _showSearchBar = true;

  bool _showStatsCard = true;

  DateTime? _startDate;
  DateTime? _endDate;

  Map<String, dynamic> _calculateStats(List<Map<String, dynamic>> commandes) {
    double totalPoidsConsomme = 0;
    Set<String> peintures = {};
    Set<String> gaz = {};
    Set<String> bellets = {};
    double totalDechet = 0;
    double totalDechetInitial = 0;

    for (var commande in commandes) {
      // Filtrer les commandes selon la plage de dates selectionnee.
      if (_startDate != null || _endDate != null) {
        final commandeDate = DateTime.parse(commande['date']);
        if (_startDate != null && commandeDate.isBefore(_startDate!)) continue;
        if (_endDate != null &&
            commandeDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
          continue;
        }
      }

      final items = commande['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        totalPoidsConsomme += totalPoidsConsomme +=
            (item['Poids consommé'] as num?)?.toDouble() ?? 0.0;

        final peintureValue = item['Peinture'];
        if (peintureValue != null) {
          final peinture = (peintureValue is num)
              ? peintureValue.toDouble()
              : double.tryParse(peintureValue.toString());
          if (peinture != null) peintures.add(peinture.toString());
        }

        final gazItem = item['Gaz'];
        if (gazItem != null) {
          final gazValue = (gazItem is num)
              ? gazItem.toDouble()
              : double.tryParse(gazItem.toString());
          if (gazValue != null) gaz.add(gazValue.toString());
        }

        final belletItem = item['bellet'];
        if (belletItem != null) {
          final belletValue = (belletItem is num)
              ? belletItem.toDouble()
              : double.tryParse(belletItem.toString());
          if (belletValue != null) bellets.add(belletValue.toString());
        }

        totalDechet += (item['dechet'] as num?)?.toDouble() ?? 0.0;
        totalDechetInitial +=
            (item['dechet initial'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return {
      'totalPoidsConsomme': totalPoidsConsomme,
      'peintures': peintures.toList(),
      'gaz': gaz.toList(),
      'bellets': bellets.toList(),
      'totalDechet': totalDechet,
      'totalDechetInitial': totalDechetInitial,
    };
  }

  // Section des statistiques resumees.
  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Indicateurs principaux',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _showStatsCard ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _showStatsCard = !_showStatsCard;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          if (_showStatsCard)
            Padding(
              padding: const EdgeInsets.all(5),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 768;

                  if (isDesktop) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Poids total consomme',
                            "${stats['totalPoidsConsomme'].toStringAsFixed(2)} kg",
                            Icons.scale,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Expanded(
                        //   child: _buildStatItem(
                        //     'Variantes de peinture',
                        //     '${stats['peintures'].length}',
                        //     Icons.format_paint,
                        //     Colors.purple,
                        //   ),
                        // ),
                        // Expanded(
                        //   child: _buildStatItem(
                        //     'Variantes de gaz',
                        //     '${stats['gaz'].length}',
                        //     Icons.air,
                        //     Colors.green,
                        //   ),
                        // ),
                        // Expanded(
                        //   child: _buildStatItem(
                        //     'Bellets',
                        //     '${stats['bellets'].length}',
                        //     Icons.category,
                        //     Colors.orange,
                        //   ),
                        // ),
                        Expanded(
                          child: _buildStatItem(
                            'Dechets totaux',
                            "${stats['totalDechet'].toStringAsFixed(2)} kg",
                            Icons.delete_outline,
                            Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatItem(
                            'Dechets initiaux',

                            "${stats['totalDechetInitial'].toStringAsFixed(2)} kg",
                            Icons.warning_amber,
                            Colors.amber,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                'Poids total consomme',
                                "${stats['totalPoidsConsomme'].toStringAsFixed(2)} kg",
                                Icons.scale,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatItem(
                                'Variantes de peinture',
                                '${stats['peintures'].length}',
                                Icons.format_paint,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                'Variantes de gaz',
                                '${stats['gaz'].length}',
                                Icons.air,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatItem(
                                'Bellets',
                                '${stats['bellets'].length}',
                                Icons.category,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                'Dechets totaux',
                                "${stats['totalDechet'].toStringAsFixed(2)} kg",
                                Icons.delete_outline,
                                Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatItem(
                                'Dechets initiaux',
                                "${stats['totalDechetInitial'].toStringAsFixed(2)} kg",
                                Icons.warning_amber,
                                Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtrer les commandes'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date de debut :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        tempStartDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey.shade600),
                        const SizedBox(width: 12),
                        Text(
                          tempStartDate != null
                              ? '${tempStartDate!.year}-${tempStartDate!.month.toString().padLeft(2, '0')}-${tempStartDate!.day.toString().padLeft(2, '0')}'
                              : 'Selectionner une date',
                          style: TextStyle(
                            color: tempStartDate != null
                                ? Colors.black
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Date de fin :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempEndDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        tempEndDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey.shade600),
                        const SizedBox(width: 12),
                        Text(
                          tempEndDate != null
                              ? '${tempEndDate!.year}-${tempEndDate!.month.toString().padLeft(2, '0')}-${tempEndDate!.day.toString().padLeft(2, '0')}'
                              : 'Selectionner une date',
                          style: TextStyle(
                            color: tempEndDate != null
                                ? Colors.black
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                Navigator.pop(context);
              },

              child: const Text('Reinitialiser'),
            ),

            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _startDate = tempStartDate;
                  _endDate = tempEndDate;
                });
                Navigator.pop(context);
                await _fetchStats();
              },

              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddInvoiceDialog() async {
    // edite_1
    final newInvoice = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AddDocumentDialog(
          onPressed: (String client, String docRef, DateTime date) {
            final newInvoice = {
              'Document_Ref': docRef,
              'Client': client,
              'date':
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              'items': [],
            };
            Navigator.of(context).pop(newInvoice);
          },
        );
      },
    );

    if (newInvoice != null) {
      await _editCommande(newInvoice, isNewInvoice: true);
    }
  }

  List<Map<String, dynamic>> _getFilteredCommandes() {
    if (_searchQuery.isEmpty) {
      return _commandes;
    }

    return _commandes.where((commande) {
      final docRef = commande['Document_Ref']?.toString().toLowerCase() ?? '';
      final client = commande['Client']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return docRef.contains(query) || client.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
    });
  }

  Future<void> _fetchOrders({bool useLoader = true}) async {
    if (!mounted) return;
    setState(() {
      if (useLoader) {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final result = await SalesApiService.fetchOrders(
        page: _currentPage,
        pageSize: _pageSize,
      );

      final orders =
          (result['orders'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      setState(() {
        _commandes
          ..clear()
          ..addAll(orders);
        _isLoading = false;
      });

      await _fetchStats();
    } catch (error, stack) {
      debugPrint('Failed to fetch orders: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Impossible de charger les donnees'),
        ),
      );
    }
  }

  Future<void> _refreshOrders() async {
    await _fetchOrders(useLoader: false);
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await SalesApiService.fetchStats(
        dateFrom: _startDate,
        dateTo: _endDate,
      );
      if (!mounted) return;
      setState(() {
        _remoteStats = stats;
      });
    } catch (error, stack) {
      debugPrint('Failed to fetch stats: $error\n$stack');
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value;
        _isSearching = value.isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredCommandes = _getFilteredCommandes();
    final stats = _remoteStats ?? _calculateStats(filteredCommandes);

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 125),
          _buildTopBar(),
          if (_showStatsCard) _buildStatsCard(stats),
          Expanded(child: _buildCommandesList(filteredCommandes)),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddInvoiceDialog(),
      backgroundColor: const Color(0xFF667EEA),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Ajouter une commande',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildTopBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Rechercher par reference ou client',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF64748B),
                          ),
                          suffixIcon: _isSearching
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey.shade400,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _isSearching = false;
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _showFilterDialog,
                      icon: const Icon(
                        Icons.filter_list_rounded,
                        color: Color(0xFF1E40AF),
                      ),

                      tooltip: 'Afficher les filtres',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          if (_showSearchBar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) {
                          _onSearchChanged(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher par reference ou client',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF64748B),
                          ),
                          suffixIcon: _isSearching
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey.shade400,
                                  ),

                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _isSearching = false;
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _showFilterDialog,
                      icon: const Icon(
                        Icons.filter_list_rounded,
                        color: Color(0xFF1E40AF),
                      ),
                      tooltip: 'Afficher les filtres',
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
  }

  Widget _buildCommandesList(List<Map<String, dynamic>> commandes) {
    if (_errorMessage != null && commandes.isEmpty) {
      return _buildErrorState(_errorMessage!);
    }

    if (_isLoading && commandes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredCommandes = commandes.where((commande) {
      if (_startDate == null && _endDate == null) return true;

      final commandeDate = DateTime.parse(commande['date']);
      if (_startDate != null && commandeDate.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null &&
          commandeDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
        return false;
      }

      return true;
    }).toList();

    if (filteredCommandes.isEmpty) {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return _buildEmptyState();
    }

    final listView = ListView.builder(
      padding: const EdgeInsets.all(0),
      itemCount: filteredCommandes.length,
      itemBuilder: (context, index) {
        final commande = filteredCommandes[index];
        return _buildCommandeCard(commande);
      },
    );

    if (_isSearching) {
      return Column(
        children: [
          _buildSearchResultsHeader(filteredCommandes.length),
          Expanded(
            child: RefreshIndicator(onRefresh: _refreshOrders, child: listView),
          ),
        ],
      );
    }

    return RefreshIndicator(onRefresh: _refreshOrders, child: listView);
  }

  Widget _buildSearchResultsHeader(int count) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.blue.shade600, size: 16),
          const SizedBox(width: 8),
          Text(
            'Resultats : $count commande${count == 1 ? '' : 's'}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandeCard(Map<String, dynamic> commande) {
    return CommandeCard(
      commande: commande,
      onView: () => _viewCommande(commande),
      onEdit: () => _editCommande(commande, isNewInvoice: false),
      onPrint: () => _printCommande(commande),
      onDelete: () => _deleteCommande(commande),
    );
  }

  void _viewCommande(Map<String, dynamic> commande) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Details de la commande ${commande["Document_Ref"]}"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Client : ${commande["Client"]}"),
              Text("Date : ${commande["date"]}"),
              const SizedBox(height: 16),
              Text("Nombre d articles : ${commande["items"]?.length ?? 0}"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _editCommande(
    Map<String, dynamic> commande, {
    required bool isNewInvoice,
  }) async {
    Map<String, dynamic> editableCommande = Map<String, dynamic>.from(commande);

    if (!isNewInvoice) {
      try {
        setState(() {
          _isLoading = true;
        });
        final freshOrder = await SalesApiService.fetchOrderByRef(
          commande['Document_Ref']?.toString() ?? '',
        );
        editableCommande = freshOrder;
      } catch (error, stack) {
        debugPrint('Failed to load order details: $error\n$stack');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible de charger la commande : $error'),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    if (!mounted) return;

    final items =
        (editableCommande['items'] as List?)?.cast<Map<String, dynamic>>() ??
        [];

    final navigator = Navigator.of(context);
    final result = await navigator.push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => SalesScreenEdit(
          items: items,
          commande: editableCommande,
          isNewInvoice: isNewInvoice,
        ),
      ),
    );

    if (result != null) {
      if (!mounted) return;
      setState(() {
        final index = _commandes.indexWhere(
          (c) => c['Document_Ref'] == result['Document_Ref'],
        );
        if (index >= 0) {
          _commandes[index] = result;
        } else {
          _commandes.insert(0, result);
        }
      });
      await _fetchStats();
      if (!mounted) return;
      await _fetchOrders(useLoader: false);
    }
  }

  // في ملف sales_screen.dart

  void _printCommande(Map<String, dynamic> commande) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Préparation de l'impression pour ${commande["Document_Ref"]}...",
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );

      // Fetch fresh order data
      final freshOrder = await SalesApiService.fetchOrderByRef(
        commande['Document_Ref']?.toString() ?? '',
      );

      // Generate PDF
      final pdfBytes = await PrintSalesDocuments.generateInvoicesPdf([
        freshOrder,
      ]);

      // Print or save the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Commande ${commande["Document_Ref"]} envoyée à l'impression",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error, stack) {
      debugPrint('Failed to print order: $error\n$stack');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'impression: $error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteCommande(Map<String, dynamic> commande) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la commande ?'),
        content: Text(
          "Confirmer la suppression de la commande ${commande["Document_Ref"]} ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (!mounted) return;

              final messenger = ScaffoldMessenger.of(context);
              setState(() {
                _isLoading = true;
              });

              try {
                await SalesApiService.deleteOrder(
                  commande['Document_Ref']?.toString() ?? '',
                );
                if (mounted) {
                  setState(() {
                    _commandes.removeWhere(
                      (c) => c['Document_Ref'] == commande['Document_Ref'],
                    );
                  });
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Commande supprimee'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _fetchStats();
                }
              } catch (error, stack) {
                debugPrint('Failed to delete order: $error\n$stack');
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression: $error'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  await _fetchOrders(useLoader: false);
                }
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

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Une erreur est survenue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _fetchOrders(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'Reessayer',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.home_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune commande enregistree',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premiere commande pour commencer.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddInvoiceDialog(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Nouvelle commande',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
