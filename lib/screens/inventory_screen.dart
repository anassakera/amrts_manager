import '../core/imports.dart';
import '../widgets/inventory_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _filteredInventory = [];
  bool _isSearching = false;
  String _searchQuery = '';
  bool _showSearchBar = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInventory();
  }

  Future<void> refresh() async {
    await _loadInventory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _filterInventory(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.trim().isNotEmpty;

      if (query.trim().isEmpty) {
        _filteredInventory = _inventory;
      } else {
        final searchQuery = query.trim().toLowerCase();
        _filteredInventory = _inventory.where((item) {
          final articleName = item['articleName']?.toString().toLowerCase() ?? '';
          final supplierRef = item['supplierRef']?.toString().toLowerCase() ?? '';
          final category = item['category']?.toString().toLowerCase() ?? '';
          final location = item['location']?.toString().toLowerCase() ?? '';

          return articleName.contains(searchQuery) ||
              supplierRef.contains(searchQuery) ||
              category.contains(searchQuery) ||
              location.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _loadInventory() async {
    // بيانات تجريبية للمخزون
    setState(() {
      _inventory = [
        {
          'id': '1',
          'articleName': 'قماش قطني عالي الجودة',
          'supplierRef': 'SUP-001',
          'category': 'أقمشة',
          'quantity': 150,
          'unit': 'متر',
          'weight': 75.5,
          'unitPrice': 25.0,
          'totalValue': 3750.0,
          'location': 'المستودع A - الرف 1',
          'minStock': 20,
          'maxStock': 200,
          'lastUpdated': '2024-01-15',
          'status': 'متوفر',
          'supplierName': 'شركة الأقمشة المتحدة',
          'invoiceNumber': 'INV-2024-001',
          'notes': 'جودة ممتازة - مناسبة للملابس الصيفية'
        },
        {
          'id': '2',
          'articleName': 'خيوط بوليستر صناعية',
          'supplierRef': 'SUP-002',
          'category': 'خيوط',
          'quantity': 80,
          'unit': 'كيلو',
          'weight': 80.0,
          'unitPrice': 15.5,
          'totalValue': 1240.0,
          'location': 'المستودع B - الرف 3',
          'minStock': 15,
          'maxStock': 100,
          'lastUpdated': '2024-01-14',
          'status': 'متوفر',
          'supplierName': 'مصنع الخيوط الحديث',
          'invoiceNumber': 'INV-2024-002',
          'notes': 'مقاومة للحرارة - مناسبة للصناعات الثقيلة'
        },
        {
          'id': '3',
          'articleName': 'أزرار بلاستيكية متنوعة',
          'supplierRef': 'SUP-003',
          'category': 'إكسسوارات',
          'quantity': 5000,
          'unit': 'قطعة',
          'weight': 25.0,
          'unitPrice': 0.5,
          'totalValue': 2500.0,
          'location': 'المستودع A - الرف 2',
          'minStock': 500,
          'maxStock': 10000,
          'lastUpdated': '2024-01-13',
          'status': 'متوفر',
          'supplierName': 'شركة الإكسسوارات العالمية',
          'invoiceNumber': 'INV-2024-003',
          'notes': 'ألوان متنوعة - أحجام مختلفة'
        },
        {
          'id': '4',
          'articleName': 'سحابات معدنية',
          'supplierRef': 'SUP-004',
          'category': 'إكسسوارات',
          'quantity': 1200,
          'unit': 'قطعة',
          'weight': 12.0,
          'unitPrice': 2.0,
          'totalValue': 2400.0,
          'location': 'المستودع B - الرف 1',
          'minStock': 200,
          'maxStock': 2000,
          'lastUpdated': '2024-01-12',
          'status': 'منخفض',
          'supplierName': 'مصنع السحابات المتطور',
          'invoiceNumber': 'INV-2024-004',
          'notes': 'مطلوب طلب جديد - الكمية منخفضة'
        },
        {
          'id': '5',
          'articleName': 'قماش جينز صناعي',
          'supplierRef': 'SUP-005',
          'category': 'أقمشة',
          'quantity': 5,
          'unit': 'متر',
          'weight': 2.5,
          'unitPrice': 35.0,
          'totalValue': 175.0,
          'location': 'المستودع A - الرف 1',
          'minStock': 50,
          'maxStock': 300,
          'lastUpdated': '2024-01-11',
          'status': 'نفذ',
          'supplierName': 'شركة الأقمشة المتحدة',
          'invoiceNumber': 'INV-2024-005',
          'notes': 'مطلوب طلب عاجل - نفذ المخزون'
        }
      ];
      _filteredInventory = _inventory;
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
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInventoryList(),
                _buildCategoriesTab(),
                _buildReportsTab(),
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
      onPressed: _showAddItemDialog,
      backgroundColor: const Color(0xFF667EEA),
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'إضافة عنصر',
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
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
                  tabs: const [
                    Tab(text: 'المخزون'),
                    Tab(text: 'الفئات'),
                    Tab(text: 'التقارير'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                        onChanged: _filterInventory,
                        decoration: InputDecoration(
                          hintText: 'البحث في المخزون...',
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
                                    _filterInventory('');
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
                      icon: const Icon(
                        Icons.filter_list_rounded,
                        color: Color(0xFF1E40AF),
                      ),
                      tooltip: 'فلتر متقدم',
                      onPressed: () {
                        // فلتر متقدم
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
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
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
                      tabs: const [
                        Tab(text: 'المخزون'),
                        Tab(text: 'الفئات'),
                        Tab(text: 'التقارير'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                      color: _showSearchBar
                          ? Colors.red.shade600
                          : const Color(0xFF1E40AF),
                    ),
                    tooltip: _showSearchBar ? 'إخفاء البحث' : 'إظهار البحث',
                    onPressed: () {
                      setState(() {
                        _showSearchBar = !_showSearchBar;
                        if (!_showSearchBar) {
                          _filterInventory('');
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
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
                        onChanged: _filterInventory,
                        decoration: InputDecoration(
                          hintText: 'البحث في المخزون...',
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
                                    _filterInventory('');
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
                      icon: const Icon(
                        Icons.filter_list_rounded,
                        color: Color(0xFF1E40AF),
                      ),
                      tooltip: 'فلتر متقدم',
                      onPressed: () {
                        // فلتر متقدم
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

  Widget _buildInventoryList() {
    final inventory = _filteredInventory;
    
    if (inventory.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadInventory,
        child: _buildEmptyState(),
      );
    }

    if (_isSearching) {
      return Column(
        children: [
          _buildSearchResultsHeader(inventory.length),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadInventory,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: inventory.length,
                itemBuilder: (context, index) {
                  final item = inventory[index];
                  return _buildInventoryCard(item);
                },
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInventory,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: inventory.length,
        itemBuilder: (context, index) {
          final item = inventory[index];
          return _buildInventoryCard(item);
        },
      ),
    );
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
            'تم العثور على $count نتيجة للبحث "$_searchQuery"',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    return InventoryCard(
      item: item,
      onView: () => _showItemDetails(item),
      onEdit: () => _editItem(item),
      onDelete: () => _deleteItem(item),
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
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد عناصر في المخزون',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإضافة عناصر جديدة للمخزون',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddItemDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'إضافة عنصر جديد',
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

  Widget _buildCategoriesTab() {
    final categories = _getCategories();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: category['color'],
              child: Icon(category['icon'], color: Colors.white),
            ),
            title: Text(category['name']),
            subtitle: Text('${category['count']} عنصر'),
            trailing: Text(
              '${category['totalValue']?.toStringAsFixed(0)} د.ك',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onTap: () => _showCategoryDetails(category),
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildReportCard(
            'إجمالي المخزون',
            '${_inventory.length}',
            'عنصر',
            Icons.inventory,
            Colors.blue,
          ),
          _buildReportCard(
            'القيمة الإجمالية',
            _getTotalValue().toStringAsFixed(0),
            'د.ك',
            Icons.attach_money,
            Colors.green,
          ),
          _buildReportCard(
            'العناصر المتوفرة',
            '${_getAvailableItemsCount()}',
            'عنصر',
            Icons.check_circle,
            Colors.green,
          ),
          _buildReportCard(
            'العناصر المنخفضة',
            '${_getLowStockItemsCount()}',
            'عنصر',
            Icons.warning,
            Colors.orange,
          ),
          _buildReportCard(
            'العناصر النافدة',
            '${_getOutOfStockItemsCount()}',
            'عنصر',
            Icons.error,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String value, String unit, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$value $unit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getCategories() {
    final categories = <String, Map<String, dynamic>>{};
    
    for (final item in _inventory) {
      final category = item['category'] as String? ?? 'غير محدد';
      if (!categories.containsKey(category)) {
        categories[category] = {
          'name': category,
          'count': 0,
          'totalValue': 0.0,
          'color': Colors.blue,
          'icon': Icons.category,
        };
      }
      categories[category]!['count'] = (categories[category]!['count'] as int) + 1;
      categories[category]!['totalValue'] = (categories[category]!['totalValue'] as double) + (item['totalValue'] as double? ?? 0.0);
    }
    
    return categories.values.toList();
  }

  double _getTotalValue() {
    return _inventory.fold(0.0, (sum, item) => sum + (item['totalValue'] as double? ?? 0.0));
  }

  int _getAvailableItemsCount() {
    return _inventory.where((item) => item['status'] == 'متوفر').length;
  }

  int _getLowStockItemsCount() {
    return _inventory.where((item) => item['status'] == 'منخفض').length;
  }

  int _getOutOfStockItemsCount() {
    return _inventory.where((item) => item['status'] == 'نفذ').length;
  }

  void _showAddItemDialog() {
    // إضافة عنصر جديد
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عنصر جديد'),
        content: const Text('سيتم إضافة هذه الميزة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['articleName'] ?? ''),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('المرجع', item['supplierRef'] ?? ''),
              _buildDetailRow('الفئة', item['category'] ?? ''),
              _buildDetailRow('الكمية', '${item['quantity']} ${item['unit']}'),
              _buildDetailRow('الوزن', '${item['weight']} كجم'),
              _buildDetailRow('سعر الوحدة', '${item['unitPrice']} د.ك'),
              _buildDetailRow('القيمة الإجمالية', '${item['totalValue']} د.ك'),
              _buildDetailRow('الموقع', item['location'] ?? ''),
              _buildDetailRow('المورد', item['supplierName'] ?? ''),
              _buildDetailRow('رقم الفاتورة', item['invoiceNumber'] ?? ''),
              _buildDetailRow('آخر تحديث', item['lastUpdated'] ?? ''),
              _buildDetailRow('الملاحظات', item['notes'] ?? ''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
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
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _editItem(Map<String, dynamic> item) {
    // تعديل العنصر
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل العنصر'),
        content: const Text('سيتم إضافة هذه الميزة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العنصر'),
        content: Text('هل أنت متأكد من حذف "${item['articleName']}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _inventory.removeWhere((i) => i['id'] == item['id']);
                _filteredInventory.removeWhere((i) => i['id'] == item['id']);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCategoryDetails(Map<String, dynamic> category) {
    final categoryItems = _inventory.where((item) => item['category'] == category['name']).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('فئة: ${category['name']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categoryItems.length,
            itemBuilder: (context, index) {
              final item = categoryItems[index];
              return ListTile(
                title: Text(item['articleName'] ?? ''),
                subtitle: Text('${item['quantity']} ${item['unit']}'),
                trailing: Text('${item['totalValue']} د.ك'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}