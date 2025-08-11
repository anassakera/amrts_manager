import 'package:amrts_manager/screens/edit_invoice_screen_buy.dart';

import '../core/imports.dart';
import 'package:printing/printing.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _filteredInvoices = [];
  List<Map<String, dynamic>> _invoices = [];
  bool _isSearching = false;
  String _searchQuery = '';
  bool _showSearchBar = true; // للتحكم في إظهار/إخفاء صف البحث

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // دالة فلترة الفواتير
  void _filterInvoices(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.trim().isNotEmpty;

      if (query.trim().isEmpty) {
        _filteredInvoices = _invoices;
      } else {
        final searchQuery = query.trim().toLowerCase();
        _filteredInvoices = _invoices.where((inv) {
          // البحث في رقم الفاتورة
          final invoiceNumber =
              inv['invoiceNumber']?.toString().toLowerCase() ?? '';
          if (invoiceNumber.contains(searchQuery)) return true;

          // البحث في اسم العميل
          final clientName = inv['clientName']?.toString().toLowerCase() ?? '';
          if (clientName.contains(searchQuery)) return true;

          // البحث في التاريخ
          final date = inv['date']?.toString().toLowerCase() ?? '';
          if (date.contains(searchQuery)) return true;

          // البحث في الحالة
          final status = inv['status']?.toString().toLowerCase() ?? '';
          if (status.contains(searchQuery)) return true;

          return false;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLang = languageProvider.currentLanguage;
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(currentLang),
          // باقي الشاشة
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvoicesList(isLocal: true),
                _buildInvoicesList(isLocal: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(currentLang),
    );
  }

  Widget _buildFloatingActionButton(String currentLang) {
    return FloatingActionButton.extended(
      onPressed: _showAddInvoiceDialog,
      backgroundColor: const Color(0xFF667EEA),
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        AppTranslations.get('add_invoice', currentLang),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTopBar(String currentLang) {
     final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;

     if (isDesktop) {
  
      // تصميم الحاسوب - TabBar والبحث في نفس الصف
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // TabBar
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E40AF),
                        Color(0xFF3B82F6),
                        Color(0xFF60A5FA),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  tabs: [
                    Tab(text: AppTranslations.get('local_import', currentLang)),
                    Tab(
                      text: AppTranslations.get('external_import', currentLang),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // صف البحث والفلتر
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  // حقل البحث
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
                        onChanged: _filterInvoices,
                        decoration: InputDecoration(
                          hintText: AppTranslations.get(
                            'search_invoice_or_client',
                            currentLang,
                          ),
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
                                    _filterInvoices('');
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
                  // أيقونة الفلتر
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
                      icon: const Icon(
                        Icons.filter_list_rounded,
                        color: Color(0xFF1E40AF),
                      ),
                      tooltip: AppTranslations.get(
                        'advanced_filter',
                        currentLang,
                      ),
                      onPressed: () { // anass
                
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // تصميم الهاتف - TabBar في الأعلى والبحث في أسفله
      return Column(
        children: [
          // صف TabBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // TabBar
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1E40AF),
                            Color(0xFF3B82F6),
                            Color(0xFF60A5FA),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                      tabs: [
                        Tab(text: AppTranslations.get('local_import', currentLang)),
                        Tab(
                          text: AppTranslations.get('external_import', currentLang),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // أيقونة التحكم في إظهار/إخفاء البحث
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
                    icon: Icon(
                      _showSearchBar ? Icons.search_off : Icons.search,
                      color: _showSearchBar ? Colors.red.shade600 : const Color(0xFF1E40AF),
                    ),
                    tooltip: _showSearchBar 
                        ? AppTranslations.get('hide_search', currentLang)
                        : AppTranslations.get('show_search', currentLang),
                    onPressed: () {
                      setState(() {
                        _showSearchBar = !_showSearchBar;
                        if (!_showSearchBar) {
                          _filterInvoices(''); // مسح البحث عند الإخفاء
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // صف البحث والفلتر (يظهر فقط عند _showSearchBar = true)
          if (_showSearchBar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // حقل البحث
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
                        onChanged: _filterInvoices,
                        decoration: InputDecoration(
                          hintText: AppTranslations.get(
                            'search_invoice_or_client',
                            currentLang,
                          ),
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
                                    _filterInvoices('');
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
                  // أيقونة الفلتر
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
                      icon: const Icon(
                        Icons.filter_list_rounded,
                        color: Color(0xFF1E40AF),
                      ),
                      tooltip: AppTranslations.get(
                        'advanced_filter',
                        currentLang,
                      ),
                      onPressed: () {
                        // Removed print statement
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
  }

  Widget _buildInvoicesList({required bool isLocal}) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLang = languageProvider.currentLanguage;
    final invoices = _filteredInvoices
        .where((inv) => inv['isLocal'] == isLocal)
        .toList();
    if (invoices.isEmpty) {
      return _buildEmptyState(isLocal, currentLang);
    }
    // إظهار عدد النتائج إذا كان البحث نشط
    if (_isSearching) {
      return Column(
        children: [
          _buildSearchResultsHeader(invoices.length, currentLang),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return _buildInvoiceCard(invoice);
              },
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return _buildInvoiceCard(invoice);
      },
    );
  }

  Widget _buildSearchResultsHeader(int count, String currentLang) {
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
            AppTranslations.get('found_results_for_search', currentLang)
                .replaceAll('{count}', count.toString())
                .replaceAll('{query}', _searchQuery),
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    return InvoiceCard(
      invoice: invoice,
      onView: () => _viewInvoice(invoice),
      onEdit: () => _editInvoice(invoice),
      onPrint: () => _printInvoice(invoice),
      onDelete: () => _deleteInvoice(invoice),
      onStatusUpdate: (String newStatus) =>
          _updateInvoiceStatus(invoice['id'].toString(), newStatus),
      onTypeUpdate: (bool newIsLocal) =>
          _updateInvoiceType(invoice['id'].toString(), newIsLocal),
    );
  }

  Widget _buildEmptyState(bool isLocal, String currentLang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            // padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLocal ? Icons.home_outlined : Icons.language_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppTranslations.get('no_invoices', currentLang),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLocal
                ? AppTranslations.get('no_local_invoices_created', currentLang)
                : AppTranslations.get(
                    'no_external_invoices_created',
                    currentLang,
                  ),
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddInvoiceDialog(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              isLocal
                  ? AppTranslations.get('add_local_invoice', currentLang)
                  : AppTranslations.get('add_external_invoice', currentLang),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLocal
                  ? Colors.green.shade600
                  : Colors.blue.shade600,
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

  bool _isAddingInvoice = false;
  Future<void> _addInvoice(Map<String, dynamic> invoice) async {
    if (_isAddingInvoice) return;
    _isAddingInvoice = true;
    
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final currentLang = languageProvider.currentLanguage;

    try {
      // التحقق من عدم وجود فاتورة بنفس الرقم أو نفس البيانات
      final invoiceNumber = invoice['invoiceNumber']?.toString() ?? '';
      final clientName = invoice['clientName']?.toString() ?? '';
      final date = invoice['date']?.toString() ?? '';
      
      final existingInvoice = _invoices.any((inv) => 
        inv['invoiceNumber']?.toString() == invoiceNumber &&
        inv['clientName']?.toString() == clientName &&
        inv['date']?.toString() == date
      );
      
      if (existingInvoice) {
        if (mounted) {
          _showSuccessMessage('الفاتورة موجودة بالفعل', Icons.error);
        }
        return;
      }
      
      final _ = await ApiServices.createInvoice(invoice);
      if (mounted) {
        // إعادة تحميل البيانات من قاعدة البيانات بدلاً من الإضافة المحلية
        await _loadInvoices();
  
         _showSuccessMessage(AppTranslations.get('invoice_added_successfully', currentLang), Icons.check_circle);

      }
    } catch (e) {
      if (mounted) {
        _showSuccessMessage(AppTranslations.get('error_adding_invoice', currentLang), Icons.error);
      }
    } finally {
      _isAddingInvoice = false;
    }
  }
  void _showSuccessMessage(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  Future<void> _updateInvoice(Map<String, dynamic> updatedInvoice) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final currentLang = languageProvider.currentLanguage;

    try {
      final String invoiceId = updatedInvoice['id'].toString();
      final response = await ApiServices.updateInvoice(
        invoiceId,
        updatedInvoice,
      );

      if (mounted) {
        setState(() {
          final index = _invoices.indexWhere(
            (invoice) => invoice['id'].toString() == updatedInvoice['id'].toString(),
          );
          if (index != -1) {
            _invoices[index] = response;
            // تحديث القائمة المفلترة
            if (_isSearching) {
              _filterInvoices(_searchQuery);
            } else {
              final filteredIndex = _filteredInvoices.indexWhere(
                (invoice) => invoice['id'].toString() == updatedInvoice['id'].toString(),
              );
              if (filteredIndex != -1) {
                _filteredInvoices[filteredIndex] = response;
              }
            }
          } else {
            // إذا لم يتم العثور على الفاتورة، إعادة تحميل القائمة
            _loadInvoices();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.get('invoice_updated_successfully', currentLang),
            ),
            backgroundColor: Colors.blue.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // Removed print statement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.get('error_updating_invoice', currentLang),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteInvoiceById(String id) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final currentLang = languageProvider.currentLanguage;

    try {
      await ApiServices.deleteInvoice(id);

      if (mounted) {
        setState(() {
          _invoices.removeWhere((invoice) => invoice['id'].toString() == id);
          _filteredInvoices.removeWhere((invoice) => invoice['id'].toString() == id);
        });
      }
    } catch (e) {
      // Removed print statement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.get('error_deleting_invoice', currentLang),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateInvoiceStatus(String id, String newStatus) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final currentLang = languageProvider.currentLanguage;

    try {
      final updatedInvoice = await ApiServices.updateInvoiceStatus(
        id,
        newStatus,
      );

      if (mounted) {
        setState(() {
          final index = _invoices.indexWhere((invoice) => invoice['id'].toString() == id);
          if (index != -1) {
            _invoices[index] = updatedInvoice;
            // تحديث القائمة المفلترة
            if (_isSearching) {
              _filterInvoices(_searchQuery);
            } else {
              final filteredIndex = _filteredInvoices.indexWhere(
                (invoice) => invoice['id'].toString() == id,
              );
              if (filteredIndex != -1) {
                _filteredInvoices[filteredIndex] = updatedInvoice;
              }
            }
          }
        });

        // إظهار رسالة تأكيد
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.get(
                'invoice_status_updated_to',
                currentLang,
              ).replaceAll('{status}', newStatus),
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Removed print statement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.get('error_updating_invoice_status', currentLang),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateInvoiceType(String id, bool newIsLocal) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final currentLang = languageProvider.currentLanguage;

    try {
      final updatedInvoice = await ApiServices.updateInvoiceType(
        id,
        newIsLocal,
      );

      if (mounted) {
        setState(() {
          final index = _invoices.indexWhere((invoice) => invoice['id'].toString() == id);
          if (index != -1) {
            _invoices[index] = updatedInvoice;
            // تحديث القائمة المفلترة
            if (_isSearching) {
              _filterInvoices(_searchQuery);
            } else {
              final filteredIndex = _filteredInvoices.indexWhere(
                (invoice) => invoice['id'].toString() == id,
              );
              if (filteredIndex != -1) {
                _filteredInvoices[filteredIndex] = updatedInvoice;
              }
            }
          }
        });

        // إظهار رسالة تأكيد
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.get(
                'invoice_type_updated_to',
                currentLang,
              ).replaceAll(
                '{type}',
                newIsLocal
                    ? AppTranslations.get('local', currentLang)
                    : AppTranslations.get('external', currentLang),
              ),
            ),
            backgroundColor: newIsLocal
                ? Colors.green.shade600
                : Colors.blue.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Removed print statement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.get('error_updating_invoice_type', currentLang),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _viewInvoice(Map<String, dynamic> invoice) async {
    try {
      // استخدام getInvoiceById للتأكد من الحصول على أحدث البيانات من API
      final updatedInvoice = await ApiServices.getInvoiceById(
        invoice['id'].toString(),
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ViewInvoiceDialog(invoice: updatedInvoice),
        );
      }
    } catch (e) {
      // Removed print statement
      // استخدام البيانات المحلية في حال فشل جلب البيانات من API
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ViewInvoiceDialog(invoice: invoice),
        );
      }
    }
  }

  Future<void> _loadInvoices() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final currentLang = languageProvider.currentLanguage;

    try {
      final invoices = await ApiServices.getAllInvoices();
      if (mounted) {
        // إزالة الفواتير المكررة بناءً على ID و invoiceNumber
        final uniqueInvoices = <Map<String, dynamic>>[];
        final seenIds = <int>{};
        final seenInvoiceNumbers = <String>{};
        
        for (final invoice in invoices) {
          final id = invoice['id'] as int?;
          final invoiceNumber = invoice['invoiceNumber']?.toString() ?? '';
          final date = invoice['date']?.toString() ?? '';
          final uniqueKey = '$invoiceNumber-$date';
          
          if (id != null && !seenIds.contains(id) && !seenInvoiceNumbers.contains(uniqueKey)) {
            seenIds.add(id);
            seenInvoiceNumbers.add(uniqueKey);
            uniqueInvoices.add(invoice);
          }
        }
        
        setState(() {
          _invoices = uniqueInvoices;
          _filteredInvoices = uniqueInvoices;
        });
      }
    } catch (e) {
      // Removed print statement
      // تظهر رسالة خطأ للمستخدم إذا فشل جلب البيانات
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppTranslations.get('error_loading_invoices', currentLang),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showAddInvoiceDialog() async {
    final isLocal = _tabController.index == 0;
    final newInvoice = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AddInvoiceDialog(isLocal: isLocal);
      },
    );

    if (newInvoice != null) {
      _addInvoice(newInvoice);
    }
  }
void _editInvoice(Map<String, dynamic> invoice) async {
  final updatedInvoice = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(
      builder: (context) => invoice['isLocal'] == true 
        ? SmartDocumentScreenBuy(  // للفواتير المحلية
            invoice: invoice,
            isLocal: invoice['isLocal'],
            clientName: invoice['clientName'],
          )
        : SmartDocumentScreen(   // للفواتير غير المحلية
            invoice: invoice,
            isLocal: invoice['isLocal'],
            clientName: invoice['clientName'],
          ),
    ),
  );
  
  if (updatedInvoice != null && mounted) {
    _updateInvoice(updatedInvoice);
  }
}

  void _printInvoice(Map<String, dynamic> invoice) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final currentLang = languageProvider.currentLanguage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.print, color: Colors.green.shade600),
            const SizedBox(width: 12),
            Text(AppTranslations.get('print_invoice', currentLang)),
          ],
        ),
        content: Text(
          AppTranslations.get(
            'do_you_want_to_print_invoice',
            currentLang,
          ).replaceAll('{number}', (invoice['invoiceNumber'] ?? '').toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.get('cancel', currentLang),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final pdfData = await PrintInvoiceService.generateInvoicesPdf([
                invoice,
              ]);
              await Printing.layoutPdf(onLayout: (format) async => pdfData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppTranslations.get('print', currentLang),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteInvoice(Map<String, dynamic> invoice) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final currentLang = languageProvider.currentLanguage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Text(AppTranslations.get('confirm_delete_invoice', currentLang)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.get('are_you_sure_delete_invoice', currentLang),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppTranslations.get('invoice_number', currentLang)}: ${invoice['invoiceNumber']?.toString() ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${AppTranslations.get('client_name', currentLang)}: ${invoice['clientName']}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppTranslations.get('warning_cannot_undo', currentLang),
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslations.get('cancel', currentLang),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await _deleteInvoiceById(invoice['id'].toString());
              if (mounted) {
                navigator.pop();
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        AppTranslations.get(
                          'invoice_deleted_successfully',
                          currentLang,
                        ),
                      ),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppTranslations.get('delete', currentLang),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
