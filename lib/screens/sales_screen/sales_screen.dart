import 'dart:async';
import 'package:amrts_manager/services/print_sales_documents.dart';
import 'package:amrts_manager/screens/sales_screen/add_document_dialog.dart';
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
  final bool _showSearchBar = true;

  void _showAddInvoiceDialog() async {
    final newInvoice = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AddDocumentDialog(
          onPressed: (String client, String docRef, DateTime date) {
            // Extract doc_type from docRef (first 2 characters if available)
            final docType = docRef.length >= 2 ? docRef.substring(0, 2) : 'BL';
            final newInvoice = {
              'Document_Ref': docRef,
              'doc_type': docType,
              'Client': client,
              'date':
                  '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} | ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
              'status': 'pending',
              'items': <Map<String, dynamic>>[],
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
      final docType = commande['doc_type']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return docRef.contains(query) ||
          client.contains(query) ||
          docType.contains(query);
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

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 125),
          _buildTopBar(),
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

    if (commandes.isEmpty) {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return _buildEmptyState();
    }

    final listView = ListView.builder(
      padding: const EdgeInsets.all(0),
      itemCount: commandes.length,
      itemBuilder: (context, index) {
        final commande = commandes[index];
        return _buildCommandeCard(commande);
      },
    );

    if (_isSearching) {
      return Column(
        children: [
          _buildSearchResultsHeader(commandes.length),
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
    final items = commande['items'] as List? ?? [];
    final totalPrice = commande['total_price'] ?? 0.0;
    final totalWeight = commande['total_weight_consumed'] ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Détails: ${commande["Document_Ref"]}"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Type',
                _getDocTypeLabel(commande['doc_type'] ?? 'BL'),
              ),
              _buildDetailRow('Client', commande['Client'] ?? 'N/A'),
              _buildDetailRow('Date', commande['date'] ?? 'N/A'),
              const Divider(),
              _buildDetailRow('Nombre d\'articles', '${items.length}'),
              _buildDetailRow(
                'Poids total',
                '${totalWeight.toStringAsFixed(2)} Kg',
              ),
              _buildDetailRow(
                'Prix total',
                '${totalPrice.toStringAsFixed(2)} DH',
              ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getDocTypeLabel(String docType) {
    switch (docType.toUpperCase()) {
      case 'BL':
        return 'Bon de Livraison';
      case 'BC':
        return 'Bon de Commande';
      case 'DE':
        return 'Devis';
      default:
        return docType;
    }
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
