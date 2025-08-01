import '../core/imports.dart';
import '../services/print_invoice_service.dart';
import '../services/invoices_api_service.dart';
import 'package:printing/printing.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InvoicesApiService _invoicesApiService = InvoicesApiService();

  
  List<Map<String, dynamic>> _invoices = [


    // {
    //   'id': '1',
    //   'clientName': 'AMR TECH SOLUTION',
    //   'invoiceNumber': 'FA-001',
    //   'date': '27/7/2025 | 11:45',
    //   'isLocal': true,
    //   'totalAmount': 0.0, // سيتم حسابها لاحقًا
    //   'status': 'Terminée',
    //   'items': [
    //     // العناصر الأصلية
    //     {
    //       'refFournisseur': 'REF001',
    //       'articles': 'FIRE PLATE 10m',
    //       'qte': 10,
    //       'poids': 10.0,
    //       'puPieces': 10.0,
    //       'exchangeRate': 11.0,
    //       'mt': 100.0,
    //       'prixAchat': 110.0,
    //       'autresCharges': 7.0,
    //       'cuHt': 117.0,
    //     },
    //     {
    //       'refFournisseur': 'REF002',
    //       'articles': 'FIRE PLATE 20m',
    //       'qte': 5,
    //       'poids': 20.0,
    //       'puPieces': 20.0,
    //       'exchangeRate': 22.0,
    //       'mt': 100.0,
    //       'prixAchat': 220.0,
    //       'autresCharges': 14.0,
    //       'cuHt': 234.0,
    //     },
    //     {
    //       'refFournisseur': 'REF003',
    //       'articles': 'FIRE PLATE 15m',
    //       'qte': 8,
    //       'poids': 15.0,
    //       'puPieces': 12.5,
    //       'exchangeRate': 10.8,
    //       'mt': 100.0,
    //       'prixAchat': 108.0,
    //       'autresCharges': 5.5,
    //       'cuHt': 113.5,
    //     },
    //     {
    //       'refFournisseur': 'REF004',
    //       'articles': 'FIRE PLATE 25m',
    //       'qte': 4,
    //       'poids': 25.0,
    //       'puPieces': 30.0,
    //       'exchangeRate': 9.5,
    //       'mt': 120.0,
    //       'prixAchat': 114.0,
    //       'autresCharges': 8.2,
    //       'cuHt': 122.2,
    //     },
    //     {
    //       'refFournisseur': 'REF005',
    //       'articles': 'FIRE PLATE 30m',
    //       'qte': 6,
    //       'poids': 30.0,
    //       'puPieces': 18.0,
    //       'exchangeRate': 12.3,
    //       'mt': 108.0,
    //       'prixAchat': 132.84,
    //       'autresCharges': 6.7,
    //       'cuHt': 139.54,
    //     },
    //     // ... (20 عنصر إضافي بنفس النمط)
    //     {
    //       'refFournisseur': 'REF025',
    //       'articles': 'FIRE PLATE 40m',
    //       'qte': 7,
    //       'poids': 40.0,
    //       'puPieces': 22.0,
    //       'exchangeRate': 11.2,
    //       'mt': 154.0,
    //       'prixAchat': 172.48,
    //       'autresCharges': 9.8,
    //       'cuHt': 182.28,
    //     },
    //     // 30 عنصر جديد مضاف
    //     {
    //       'refFournisseur': 'REF026',
    //       'articles': 'FIRE PLATE 12m',
    //       'qte': 9,
    //       'poids': 12.0,
    //       'puPieces': 11.0,
    //       'exchangeRate': 10.5,
    //       'mt': 99.0,
    //       'prixAchat': 103.95,
    //       'autresCharges': 7.5,
    //       'cuHt': 111.45,
    //     },
    //     {
    //       'refFournisseur': 'REF027',
    //       'articles': 'FIRE PLATE 18m',
    //       'qte': 6,
    //       'poids': 18.0,
    //       'puPieces': 16.0,
    //       'exchangeRate': 13.0,
    //       'mt': 96.0,
    //       'prixAchat': 124.8,
    //       'autresCharges': 6.0,
    //       'cuHt': 130.8,
    //     },
    //     {
    //       'refFournisseur': 'REF028',
    //       'articles': 'FIRE PLATE 22m',
    //       'qte': 5,
    //       'poids': 22.0,
    //       'puPieces': 20.0,
    //       'exchangeRate': 11.5,
    //       'mt': 110.0,
    //       'prixAchat': 126.5,
    //       'autresCharges': 9.0,
    //       'cuHt': 135.5,
    //     },
    //     {
    //       'refFournisseur': 'REF029',
    //       'articles': 'FIRE PLATE 28m',
    //       'qte': 3,
    //       'poids': 28.0,
    //       'puPieces': 25.0,
    //       'exchangeRate': 10.0,
    //       'mt': 75.0,
    //       'prixAchat': 75.0,
    //       'autresCharges': 5.0,
    //       'cuHt': 80.0,
    //     },
    //     {
    //       'refFournisseur': 'REF030',
    //       'articles': 'FIRE PLATE 35m',
    //       'qte': 4,
    //       'poids': 35.0,
    //       'puPieces': 28.0,
    //       'exchangeRate': 12.8,
    //       'mt': 140.0,
    //       'prixAchat': 179.2,
    //       'autresCharges': 8.5,
    //       'cuHt': 187.7,
    //     },
    //     {
    //       'refFournisseur': 'REF031',
    //       'articles': 'FIRE PLATE 14m',
    //       'qte': 11,
    //       'poids': 14.0,
    //       'puPieces': 13.0,
    //       'exchangeRate': 10.2,
    //       'mt': 143.0,
    //       'prixAchat': 145.86,
    //       'autresCharges': 7.0,
    //       'cuHt': 152.86,
    //     },
    //     {
    //       'refFournisseur': 'REF032',
    //       'articles': 'FIRE PLATE 16m',
    //       'qte': 7,
    //       'poids': 16.0,
    //       'puPieces': 14.0,
    //       'exchangeRate': 11.9,
    //       'mt': 112.0,
    //       'prixAchat': 133.28,
    //       'autresCharges': 6.5,
    //       'cuHt': 139.78,
    //     },
    //     {
    //       'refFournisseur': 'REF033',
    //       'articles': 'FIRE PLATE 24m',
    //       'qte': 5,
    //       'poids': 24.0,
    //       'puPieces': 21.0,
    //       'exchangeRate': 10.7,
    //       'mt': 105.0,
    //       'prixAchat': 112.35,
    //       'autresCharges': 8.0,
    //       'cuHt': 120.35,
    //     },
    //     {
    //       'refFournisseur': 'REF034',
    //       'articles': 'FIRE PLATE 26m',
    //       'qte': 4,
    //       'poids': 26.0,
    //       'puPieces': 23.0,
    //       'exchangeRate': 9.8,
    //       'mt': 92.0,
    //       'prixAchat': 90.16,
    //       'autresCharges': 5.2,
    //       'cuHt': 95.36,
    //     },
    //     {
    //       'refFournisseur': 'REF035',
    //       'articles': 'FIRE PLATE 32m',
    //       'qte': 6,
    //       'poids': 32.0,
    //       'puPieces': 27.0,
    //       'exchangeRate': 12.1,
    //       'mt': 172.8,
    //       'prixAchat': 209.088,
    //       'autresCharges': 9.5,
    //       'cuHt': 218.588,
    //     },
    //     {
    //       'refFournisseur': 'REF036',
    //       'articles': 'FIRE PLATE 11m',
    //       'qte': 10,
    //       'poids': 11.0,
    //       'puPieces': 10.5,
    //       'exchangeRate': 10.3,
    //       'mt': 105.0,
    //       'prixAchat': 108.15,
    //       'autresCharges': 7.2,
    //       'cuHt': 115.35,
    //     },
    //     {
    //       'refFournisseur': 'REF037',
    //       'articles': 'FIRE PLATE 19m',
    //       'qte': 5,
    //       'poids': 19.0,
    //       'puPieces': 15.5,
    //       'exchangeRate': 12.9,
    //       'mt': 77.5,
    //       'prixAchat': 99.975,
    //       'autresCharges': 5.8,
    //       'cuHt': 105.775,
    //     },
    //     {
    //       'refFournisseur': 'REF038',
    //       'articles': 'FIRE PLATE 23m',
    //       'qte': 4,
    //       'poids': 23.0,
    //       'puPieces': 19.5,
    //       'exchangeRate': 11.1,
    //       'mt': 92.0,
    //       'prixAchat': 102.12,
    //       'autresCharges': 7.8,
    //       'cuHt': 109.92,
    //     },
    //     {
    //       'refFournisseur': 'REF039',
    //       'articles': 'FIRE PLATE 27m',
    //       'qte': 3,
    //       'poids': 27.0,
    //       'puPieces': 22.5,
    //       'exchangeRate': 9.7,
    //       'mt': 67.5,
    //       'prixAchat': 65.475,
    //       'autresCharges': 4.5,
    //       'cuHt': 70.0,
    //     },
    //     {
    //       'refFournisseur': 'REF040',
    //       'articles': 'FIRE PLATE 33m',
    //       'qte': 5,
    //       'poids': 33.0,
    //       'puPieces': 26.0,
    //       'exchangeRate': 12.5,
    //       'mt': 165.0,
    //       'prixAchat': 206.25,
    //       'autresCharges': 9.2,
    //       'cuHt': 215.45,
    //     },
    //     {
    //       'refFournisseur': 'REF041',
    //       'articles': 'FIRE PLATE 13m',
    //       'qte': 12,
    //       'poids': 13.0,
    //       'puPieces': 11.5,
    //       'exchangeRate': 10.1,
    //       'mt': 138.0,
    //       'prixAchat': 139.38,
    //       'autresCharges': 7.3,
    //       'cuHt': 146.68,
    //     },
    //     {
    //       'refFournisseur': 'REF042',
    //       'articles': 'FIRE PLATE 17m',
    //       'qte': 8,
    //       'poids': 17.0,
    //       'puPieces': 15.0,
    //       'exchangeRate': 11.8,
    //       'mt': 120.0,
    //       'prixAchat': 141.6,
    //       'autresCharges': 6.8,
    //       'cuHt': 148.4,
    //     },
    //     {
    //       'refFournisseur': 'REF043',
    //       'articles': 'FIRE PLATE 21m',
    //       'qte': 6,
    //       'poids': 21.0,
    //       'puPieces': 18.0,
    //       'exchangeRate': 10.9,
    //       'mt': 108.0,
    //       'prixAchat': 117.72,
    //       'autresCharges': 7.9,
    //       'cuHt': 125.62,
    //     },
    //     {
    //       'refFournisseur': 'REF044',
    //       'articles': 'FIRE PLATE 29m',
    //       'qte': 4,
    //       'poids': 29.0,
    //       'puPieces': 24.0,
    //       'exchangeRate': 9.6,
    //       'mt': 96.0,
    //       'prixAchat': 92.16,
    //       'autresCharges': 5.1,
    //       'cuHt': 97.26,
    //     },
    //     {
    //       'refFournisseur': 'REF045',
    //       'articles': 'FIRE PLATE 34m',
    //       'qte': 5,
    //       'poids': 34.0,
    //       'puPieces': 28.5,
    //       'exchangeRate': 12.7,
    //       'mt': 170.0,
    //       'prixAchat': 215.9,
    //       'autresCharges': 9.3,
    //       'cuHt': 225.2,
    //     },
    //     {
    //       'refFournisseur': 'REF046',
    //       'articles': 'FIRE PLATE 15.5m',
    //       'qte': 9,
    //       'poids': 15.5,
    //       'puPieces': 13.5,
    //       'exchangeRate': 10.4,
    //       'mt': 121.5,
    //       'prixAchat': 126.36,
    //       'autresCharges': 7.6,
    //       'cuHt': 133.96,
    //     },
    //     {
    //       'refFournisseur': 'REF047',
    //       'articles': 'FIRE PLATE 18.5m',
    //       'qte': 7,
    //       'poids': 18.5,
    //       'puPieces': 16.5,
    //       'exchangeRate': 12.0,
    //       'mt': 114.5,
    //       'prixAchat': 137.4,
    //       'autresCharges': 6.9,
    //       'cuHt': 144.3,
    //     },
    //     {
    //       'refFournisseur': 'REF048',
    //       'articles': 'FIRE PLATE 23.5m',
    //       'qte': 4,
    //       'poids': 23.5,
    //       'puPieces': 20.5,
    //       'exchangeRate': 11.3,
    //       'mt': 94.0,
    //       'prixAchat': 106.22,
    //       'autresCharges': 8.1,
    //       'cuHt': 114.32,
    //     },
    //     {
    //       'refFournisseur': 'REF049',
    //       'articles': 'FIRE PLATE 28.5m',
    //       'qte': 3,
    //       'poids': 28.5,
    //       'puPieces': 23.5,
    //       'exchangeRate': 9.9,
    //       'mt': 70.5,
    //       'prixAchat': 69.795,
    //       'autresCharges': 4.8,
    //       'cuHt': 74.595,
    //     },
    //     {
    //       'refFournisseur': 'REF050',
    //       'articles': 'FIRE PLATE 35.5m',
    //       'qte': 5,
    //       'poids': 35.5,
    //       'puPieces': 29.0,
    //       'exchangeRate': 12.9,
    //       'mt': 177.5,
    //       'prixAchat': 228.975,
    //       'autresCharges': 9.7,
    //       'cuHt': 238.675,
    //     },
    //   ],
    //   'summary': {
    //     'factureNumber': 'CI-SSA240103002,1',
    //     'transit': 30,
    //     'droitDouane': 30,
    //     'chequeChange': 0,
    //     'freiht': 0,
    //     'autres': 0,
    //     'total': 0,
    //     'txChange': 0,
    //     'poidsTotal': 0.0, // سيتم حسابها لاحقًا
    //   },
    // },
    // {
    //   'id': '2',
    //   'clientName': 'INTERNATIONAL TRADING CO',
    //   'invoiceNumber': 'FA-002',
    //   'date': '28/7/2025 | 14:30',
    //   'isLocal': false,
    //   'totalAmount': 18500.0,
    //   'status': 'En cours',
    //   'items': [
    //     {
    //       'refFournisseur': 'REF101',
    //       'articles': 'STEEL PLATE 15m',
    //       'qte': 12,
    //       'poids': 15.0,
    //       'puPieces': 25.0,
    //       'exchangeRate': 12.5,
    //       'mt': 300.0,
    //       'prixAchat': 375.0,
    //       'autresCharges': 12.0,
    //       'cuHt': 387.0,
    //     },
    //     {
    //       'refFournisseur': 'REF102',
    //       'articles': 'ALUMINUM SHEET 8m',
    //       'qte': 8,
    //       'poids': 8.0,
    //       'puPieces': 35.0,
    //       'exchangeRate': 11.8,
    //       'mt': 280.0,
    //       'prixAchat': 330.4,
    //       'autresCharges': 15.5,
    //       'cuHt': 345.9,
    //     },
    //   ],
    //   'summary': {
    //     'factureNumber': 'CI-SSA240103002,2',
    //     'transit': 45,
    //     'droitDouane': 55,
    //     'chequeChange': 0,
    //     'freiht': 120,
    //     'autres': 25,
    //     'total': 0,
    //     'txChange': 0,
    //     'poidsTotal': 280.0,
    //   },
    // },
 
 
  ];

  // متغيرات البحث والفلتر
  String _searchQuery = '';
  // يمكن إضافة متغيرات فلتر إضافية لاحقاً

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInvoices();
  }

  // إضافة وظيفة جديدة لتحميل الفواتير من API
  Future<void> _loadInvoices() async {
    try {
      final invoices = await _invoicesApiService.getAllInvoices();
      setState(() {
        _invoices = invoices;
      });
    } catch (e) {
      print('Error loading invoices: $e');
      // تظهر رسالة خطأ للمستخدم إذا فشل جلب البيانات
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحميل الفواتير'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
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
                      tabs: const [
                        Tab(text: 'استيراد محلي'),
                        Tab(text: 'استيراد خارجي'),
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
                                color: Colors.black.withValues(alpha:0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'بحث عن فاتورة أو عميل...',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                              color: Colors.black.withValues(alpha:0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF1E40AF)),
                          tooltip: 'فلترة متقدمة',
                          onPressed: () {
                            print(_invoicesApiService);
                            print(_invoices);
                            // showDialog(
                            //   context: context,
                            //   builder: (context) => AlertDialog(
                            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            //     title: const Text('خيارات الفلترة'),
                            //     content: const Text('هنا يمكن إضافة خيارات فلترة متقدمة لاحقاً.'),
                            //     actions: [
                            //       TextButton(
                            //         onPressed: () => Navigator.pop(context),
                            //         child: const Text('إغلاق'),
                            //       ),
                            //     ],
                            //   ),
                            // );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddInvoiceDialog,
        backgroundColor: const Color(0xFF667EEA),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'إضافة فاتورة',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInvoicesList({required bool isLocal}) {
    final invoices = _invoices
        .where((inv) => inv['isLocal'] == isLocal)
        .where((inv) {
          if (_searchQuery.trim().isEmpty) return true;
          final query = _searchQuery.trim().toLowerCase();
          return (inv['invoiceNumber']?.toString().toLowerCase().contains(query) ?? false) ||
                 (inv['clientName']?.toString().toLowerCase().contains(query) ?? false);
        })
        .toList();

    if (invoices.isEmpty) {
      return _buildEmptyState(isLocal);
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];

        return InvoiceCard(
          invoice: invoice,
          onView: () => _viewInvoice(invoice),
          onEdit: () => _editInvoice(invoice),
          onPrint: () => _printInvoice(invoice),
          onDelete: () => _deleteInvoice(invoice),
          onStatusUpdate: (String newStatus) =>
              _updateInvoiceStatus(invoice['id'], newStatus),
          onTypeUpdate: (bool newIsLocal) =>
              _updateInvoiceType(invoice['id'], newIsLocal),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isLocal) {
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
            'لا توجد فواتير',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLocal
                ? 'لم يتم إنشاء أي فاتورة استيراد محلي بعد'
                : 'لم يتم إنشاء أي فاتورة استيراد خارجي بعد',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddInvoiceDialog(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              isLocal ? 'إضافة فاتورة محلية' : 'إضافة فاتورة خارجية',
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

  Future<void> _addInvoice(Map<String, dynamic> invoice) async {
    try {
      final addedInvoice = await _invoicesApiService.addInvoice(invoice);
      setState(() {
        _invoices.insert(0, addedInvoice);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة الفاتورة بنجاح'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      print('Error adding invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إضافة الفاتورة'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _updateInvoice(Map<String, dynamic> updatedInvoice) async {
    try {
      final String invoiceId = updatedInvoice['id'].toString();
      final response = await _invoicesApiService.updateInvoice(invoiceId, updatedInvoice);

      setState(() {
        final index = _invoices.indexWhere(
          (invoice) => invoice['id'] == updatedInvoice['id'],
        );
        if (index != -1) {
          _invoices[index] = response;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث الفاتورة بنجاح'),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      print('Error updating invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحديث الفاتورة'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _deleteInvoiceById(String id) async {
    try {
      await _invoicesApiService.deleteInvoice(id);

      setState(() {
        _invoices.removeWhere((invoice) => invoice['id'] == id);
      });
    } catch (e) {
      print('Error deleting invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء حذف الفاتورة'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _updateInvoiceStatus(String id, String newStatus) async {
    try {
      final updatedInvoice = await _invoicesApiService.updateInvoiceStatus(id, newStatus);

      setState(() {
        final index = _invoices.indexWhere((invoice) => invoice['id'] == id);
        if (index != -1) {
          _invoices[index] = updatedInvoice;
        }
      });

      // إظهار رسالة تأكيد
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الفاتورة إلى: $newStatus'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error updating invoice status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحديث حالة الفاتورة'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // أضف الدالة التالية لتحديث نوع الفاتورة
  Future<void> _updateInvoiceType(String id, bool newIsLocal) async {
    try {
      final updatedInvoice = await _invoicesApiService.updateInvoiceType(id, newIsLocal);

      setState(() {
        final index = _invoices.indexWhere((invoice) => invoice['id'] == id);
        if (index != -1) {
          _invoices[index] = updatedInvoice;
        }
      });

      // إظهار رسالة تأكيد
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديث نوع الفاتورة إلى: ${newIsLocal ? 'محلي' : 'خارجي'}',
          ),
          backgroundColor: newIsLocal
            ? Colors.green.shade600
            : Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
      );
    } catch (e) {
      print('Error updating invoice type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحديث نوع الفاتورة'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
        builder: (context) => SmartDocumentScreen(
          invoice: invoice,
          isLocal: invoice['isLocal'],
          clientName: invoice['clientName'],
        ),
      ),
    );

    if (updatedInvoice != null) {
      _updateInvoice(updatedInvoice);
    }
  }

  void _viewInvoice(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (context) => ViewInvoiceDialog(invoice: invoice),
    );
  }

  void _printInvoice(Map<String, dynamic> invoice) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.print, color: Colors.green.shade600),
            const SizedBox(width: 12),
            const Text('طباعة الفاتورة'),
          ],
        ),
        content: Text(
          'هل تريد طباعة الفاتورة رقم  ${invoice['invoiceNumber']}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600)),
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
            child: const Text('طباعة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteInvoice(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('تأكيد الحذف'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حذف هذه الفاتورة؟'),
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
                    'رقم الفاتورة: ${invoice['invoiceNumber']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('العميل: ${invoice['clientName']}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تحذير: لا يمكن التراجع عن هذا الإجراء',
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
            child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteInvoiceById(invoice['id']);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف الفاتورة بنجاح'),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
